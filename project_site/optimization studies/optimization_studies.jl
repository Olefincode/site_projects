### A Pluto.jl notebook ###
# v0.20.6

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ ff3a0990-1f25-11f0-0c4a-4388fb2af02c
begin
	import Pkg; Pkg.activate()
	using CairoMakie, DataFrames, CSV, ColorSchemes, FileIO, PlutoUI, GLMakie
end

# ╔═╡ 468a0773-0e66-44a3-b81a-d15393e91929
TableOfContents()

# ╔═╡ 0977b256-ef1a-41f4-9aea-f723ddc576de
md"# Reading in Case Study Data"

# ╔═╡ 308c65f0-188a-4d23-908a-813807a0c263
function name_search(name::String)
	found_it = findlast("-", name)
	if found_it == nothing
		return name
	else
		return name[found_it[1]+2:end]
	end
end

# ╔═╡ 2da18b9e-399f-4934-affa-565dd724612f
function read_in_optimization(name::String="reactor")
	if name == "reactor"
		fname = "Methanol_Reactor_Data.csv"
		column_len = 10
	elseif name == "H2"
		fname = "Electrolysis_H2_Molar_Flow_Data.csv"
		column_len = 6
	else
		error("please input either 'reactor' to import reactor conditions case study data or 'H2' to import electrolysis H2 molar flow rate case study data")
	end
	reactor_optimizing_data = CSV.read(
		joinpath(pwd(), fname), DataFrame, header=1, 
		types=[String for i = 1:column_len]
	)
	column_names = names(reactor_optimizing_data)
	reactor_optimizing_data = reactor_optimizing_data[completecases(reactor_optimizing_data), :]
	for (i, column) in enumerate(column_names)
		t = typeof(reactor_optimizing_data[1, column])
		if i > 1
			reactor_optimizing_data[!, column] = map(string -> parse(Float64, string), reactor_optimizing_data[!, column])
		end
	end
	reactor_optimizing_data = filter(row -> !(row.State == "Minimum" || row.State == "Maximum"),  reactor_optimizing_data)
	if name == "H2"
		new_names = [name_search(i) for i in names(reactor_optimizing_data)]
		copy_reactor_optimizing_data = deepcopy(reactor_optimizing_data)
		rename!(copy_reactor_optimizing_data, new_names)
		return copy_reactor_optimizing_data
	elseif name == "reactor"
		return reactor_optimizing_data
	end
end

# ╔═╡ b0136f19-3785-4176-834a-62188e5b34f4
reactor_optimizing_data = read_in_optimization()

# ╔═╡ 04f764d8-6a52-4ccd-9bf1-e9683080bc97
reactor_column_names = names(reactor_optimizing_data)

# ╔═╡ 06220b77-9ac7-4524-9ace-6c6f9d6b51bd
H2_optimizing_data = read_in_optimization("H2")

# ╔═╡ 0f4a6f2c-9499-41e2-9c3c-629b5002ac99
H2_column_names = names(H2_optimizing_data)

# ╔═╡ 94980f0b-010e-4b6b-b21d-ac5fbd372936
md"# Plotting Functions"

# ╔═╡ 91000870-8f88-40ea-a3e2-e1c2643157d7
md"## 3D Plotting Functions (for reactor operating conditions)"

# ╔═╡ 3e35fecf-fa60-4f16-838b-7e48e0572c9e
md"### specified parameter (all tube lengths)"

# ╔═╡ 50bd288b-ab0d-42d3-89a7-2fbf672f2a33
function reactor_optimizing_plot(ylabel::String; map=:berlin)
	unit = (occursin("Flow", ylabel) ? " (kmol/hr)" : "")
	fig = Figure(size=(700, 500))
	ax = Axis3(fig[1, 1], aspect = (1, 1, 1), title = ylabel*unit,
		xlabel=reactor_column_names[2]*"\n(°C)", ylabel=reactor_column_names[3]*"\n(kPa)", zlabel=ylabel*unit, xlabeloffset=40, ylabeloffset=45, zlabeloffset=70)
	x = [i for i in reactor_optimizing_data[:, reactor_column_names[2]]]
	y = [i for i in reactor_optimizing_data[:, reactor_column_names[3]]]
	z = [i for i in reactor_optimizing_data[:, ylabel]]
	h = [i for i in reactor_optimizing_data[:, reactor_column_names[4]]]
	scatter!(ax,
		x,
		y,
		z,
		color = h,
		colormap = map
	)
	Colorbar(fig[1, 2], limits = (minimum(h), maximum(h)), colormap = map, flipaxis = false, label = reactor_column_names[4])
	return display(fig)
end

# ╔═╡ f99b692d-a61b-4bcd-be3b-d347e8443181
md" ### specified tube length (all parameters)"

# ╔═╡ 5b6236be-ecd4-41ff-8fa1-426feb25aa16
function filter_tube_lengths(length::Float64)
	@assert any(x -> x == length, unique(reactor_optimizing_data[:, "BWR - Tube Length"]))
	df = filter(row -> row."BWR - Tube Length" == length, reactor_optimizing_data)
	fig = Figure(size = (1600, 900))
	Label(fig[0, 2], "Reactor Results for Tube Length : $length m", fontsize = 30, font=:bold)
	x = [i for i in df[:, reactor_column_names[2]]]
	y = [i for i in df[:, reactor_column_names[3]]]
	h = [i for i in df[:, "BWR - Tube Length"]]
	@assert size(unique(h)) == (1,)

	for (i, ylabel) in enumerate(reactor_column_names[5:end])
		unit = (occursin("Flow", ylabel) ? "molar flow (kmol/hr)" : "molar fraction")
		if occursin("(CO)", ylabel)
			chem = "CO "
		elseif occursin("(CO2)", ylabel)
			chem = "CO2 "
		elseif occursin("(Methanol)", ylabel)
			chem = "MeOH "
		else
		end
		if i <= 3
			ax = Axis3(fig[1, i], aspect = (1, 1, 1), title = ylabel,
				xlabel=reactor_column_names[2]*"\n(°C)", ylabel=reactor_column_names[3]*"\n(kPa)", zlabel=chem*unit, xlabeloffset=35, ylabeloffset=40, zlabeloffset=80)
		else
			ax = Axis3(fig[2, i-3], aspect = (1, 1, 1), title = ylabel,
				xlabel=reactor_column_names[2]*"\n(°C)", ylabel=reactor_column_names[3]*"\n(kPa)", zlabel=chem*unit, xlabeloffset=25, ylabeloffset=40, zlabeloffset=80)
		end
		z = [i for i in df[:, ylabel]]
		scatter!(ax,
				x,
				y,
				z,
				color= cgrad(:berlin10)[9.75]
			)
	end
	rowgap!(fig.layout, 20)
	colgap!(fig.layout, -60)
	resize_to_layout!(fig)
	return display(fig)
end

# ╔═╡ 3606f8a1-8a79-4553-94f6-a9827ef8bb5e
md" ## 2D Plotting Functions (for electrolysis H₂ molar flow rate) "

# ╔═╡ 50b3ad57-fff2-4cec-b661-331363fb4f96
function molar_flow_rates()
	fig = Figure(size = (1800, 900))
	df = H2_optimizing_data
	Label(fig[0, 2], "Electrolytic H₂ Molar Flow Rate Results", fontsize = 30, font=:bold)
	x = [i for i in df[:, H2_column_names[6]]]
	for (i, ylabel) in enumerate(H2_column_names[3:5])
		unit = (occursin("Flow", ylabel) ? "molar flow (kmol/hr)" : "molar fraction")
		if occursin("(CO)", ylabel)
			chem = "CO "
		elseif occursin("(CO2)", ylabel)
			chem = "CO2 "
		elseif occursin("(Methanol)", ylabel)
			chem = "MeOH "
		else
		end
		ax = Axis(fig[1, i], title = ylabel,
				xlabel="H₂ Molar Flow Rate\n(kmol/hr)",
				ylabel="Molar Flow \n(kmol/hr)",
				xminorticksvisible = true, yminorticksvisible = true
				 )
		y = [i for i in df[:, ylabel]]
		lines!(ax,
				x,
				y,
			   linewidth=2,
			   color = y, colormap = :berlin
			)
		if ylabel == "Master Comp Molar Flow (CO)"
			minimum_CO_id = argmin(H2_optimizing_data[:, ylabel])
			minimum_CO_H2mf = H2_optimizing_data[:, "Molar Flow"][minimum_CO_id]
			minimum_CO_COmf = H2_optimizing_data[:, ylabel][minimum_CO_id]
			println("Minimum CO formation of $minimum_CO_COmf kmol/hr at H₂ molar flow rate of $minimum_CO_H2mf kmol/hr")
		end
		y_diff = y[argmax(y)] - y[2]
		xlims!(ax, low=0.0, high=nothing)
		ylims!(ax, low=0.0, high=y[argmax(y)] + y_diff)
	end
	rowgap!(fig.layout, 20)
	colgap!(fig.layout, 50)
	resize_to_layout!(fig)
	return display(fig)
end

# ╔═╡ 7e6da3bc-1f24-4d5d-9557-876d0595bf66
md"# Plotting Case Study Results"

# ╔═╡ 3532ff67-54af-4735-b83e-eaffd01e777d
md"## Reactor Operating Condition Results"

# ╔═╡ a203e143-1e5d-4ab1-8911-4a1a3a99e97f
md"""
!!! warning "Read Before Proceeding"
	Select graphs using the drop down menu below ↓
"""

# ╔═╡ bfc69afc-3f93-4eb8-b869-f94730ff32e4
@bind favourite_function Select(["Specified Tube Length (All Parameters)", "Specified Parameter (All Tube Lengths)"])

# ╔═╡ 8fbf9aac-fe46-4dc6-9a95-0931bd11b3aa
md"""
!!! note
	Select the type of graphs you want to see / interact with and adjust the corresponding interactive widgets according to your specifications.

	**Specified Tube Length (All Parameters)**

		→ will display all effluent properties for specified tube length
		→ specified tube length can be adjusted using a slider

	**Specified Parameter (All Tube Lengths)**

		→ will display all tube lengths for specified effluent property
		→ specified properties can be selected using a dropdown menu

	FYI: Toggles will only appear under the function you've selected in the above dropdown menu
"""

# ╔═╡ 497f74fd-4c36-4d47-bc3c-b4163985fc96
md""" ### Specified Tube Length (All Parameters)"""

# ╔═╡ de93c1b9-51f6-4126-98ba-26c8968f1492
if favourite_function == "Specified Tube Length (All Parameters)"
	@bind len PlutoUI.Slider(unique(reactor_optimizing_data[:, "BWR - Tube Length"]),
					 default=8.754)
end

# ╔═╡ f7de3567-8ede-4c11-8304-55af0e8c5e18
if favourite_function == "Specified Tube Length (All Parameters)"
	len
end

# ╔═╡ d762f425-899d-4cda-8fb4-de69e063d1c8
if favourite_function == "Specified Tube Length (All Parameters)"
	@warn "graphs should appear in a popup screen labeled 'Makie'"
	filter_tube_lengths(len)
end

# ╔═╡ 2190d88a-a058-49b9-af8a-b2287a3a120b
md""" ### Specified Parameter (All Tube Lengths)"""

# ╔═╡ caf489af-5b65-4344-be1a-ba2e03786ac5
if favourite_function == "Specified Parameter (All Tube Lengths)"
	@bind parameter Select(reactor_column_names[5:end])
end

# ╔═╡ 529849a7-cb3e-4944-a6fd-091341500d95
if favourite_function == "Specified Parameter (All Tube Lengths)"
	parameter
end

# ╔═╡ 61e389fc-afad-4195-ac35-54006392ca2d
if favourite_function == "Specified Parameter (All Tube Lengths)"
	@warn "graph should appear in a popup screen labeled 'Makie'"
	reactor_optimizing_plot(parameter)
end

# ╔═╡ 71731963-a509-401d-9102-24bd67b3f434
md"## Electrolysis H₂ Molar Flow Rate Results "

# ╔═╡ 3e143713-ea98-4afd-a4f0-1df0375c40bc
@bind display_H2_results CheckBox(default=false)

# ╔═╡ 8473de1a-b835-49f5-aa85-69cf96268ce6
if display_H2_results
	@warn "now displaying case study H₂ molar flow rate results, reactor case study results may not be visible during this time!"
	molar_flow_rates()
	@warn "graph should appear in a popup screen labeled 'Makie'"
end

# ╔═╡ Cell order:
# ╠═ff3a0990-1f25-11f0-0c4a-4388fb2af02c
# ╠═468a0773-0e66-44a3-b81a-d15393e91929
# ╟─0977b256-ef1a-41f4-9aea-f723ddc576de
# ╟─308c65f0-188a-4d23-908a-813807a0c263
# ╟─2da18b9e-399f-4934-affa-565dd724612f
# ╟─b0136f19-3785-4176-834a-62188e5b34f4
# ╠═04f764d8-6a52-4ccd-9bf1-e9683080bc97
# ╟─06220b77-9ac7-4524-9ace-6c6f9d6b51bd
# ╟─0f4a6f2c-9499-41e2-9c3c-629b5002ac99
# ╟─94980f0b-010e-4b6b-b21d-ac5fbd372936
# ╟─91000870-8f88-40ea-a3e2-e1c2643157d7
# ╠═3e35fecf-fa60-4f16-838b-7e48e0572c9e
# ╟─50bd288b-ab0d-42d3-89a7-2fbf672f2a33
# ╟─f99b692d-a61b-4bcd-be3b-d347e8443181
# ╟─5b6236be-ecd4-41ff-8fa1-426feb25aa16
# ╟─3606f8a1-8a79-4553-94f6-a9827ef8bb5e
# ╠═50b3ad57-fff2-4cec-b661-331363fb4f96
# ╟─7e6da3bc-1f24-4d5d-9557-876d0595bf66
# ╟─3532ff67-54af-4735-b83e-eaffd01e777d
# ╟─a203e143-1e5d-4ab1-8911-4a1a3a99e97f
# ╟─bfc69afc-3f93-4eb8-b869-f94730ff32e4
# ╟─8fbf9aac-fe46-4dc6-9a95-0931bd11b3aa
# ╟─497f74fd-4c36-4d47-bc3c-b4163985fc96
# ╟─de93c1b9-51f6-4126-98ba-26c8968f1492
# ╟─f7de3567-8ede-4c11-8304-55af0e8c5e18
# ╟─d762f425-899d-4cda-8fb4-de69e063d1c8
# ╟─2190d88a-a058-49b9-af8a-b2287a3a120b
# ╟─caf489af-5b65-4344-be1a-ba2e03786ac5
# ╟─529849a7-cb3e-4944-a6fd-091341500d95
# ╟─61e389fc-afad-4195-ac35-54006392ca2d
# ╟─71731963-a509-401d-9102-24bd67b3f434
# ╠═3e143713-ea98-4afd-a4f0-1df0375c40bc
# ╠═8473de1a-b835-49f5-aa85-69cf96268ce6
