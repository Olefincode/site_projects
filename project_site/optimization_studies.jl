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
	using CairoMakie, DataFrames, CSV, ColorSchemes, FileIO, PlutoUI, GLMakie, PlutoSliderServer
end

# ╔═╡ 468a0773-0e66-44a3-b81a-d15393e91929
TableOfContents()

# ╔═╡ 0977b256-ef1a-41f4-9aea-f723ddc576de
md"# Reading in Case Study Data"

# ╔═╡ d447c788-66e6-462a-8103-edde30e1361f
begin
	reactor_optimizing_data = CSV.read(
		joinpath(pwd(), "Methanol_Reactor_Data.csv"), DataFrame, header=1,
		types=[String, String, String, String, String, String, String, String,
			String, String]
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
end

# ╔═╡ 94980f0b-010e-4b6b-b21d-ac5fbd372936
md"# Plotting Functions"

# ╔═╡ 50bd288b-ab0d-42d3-89a7-2fbf672f2a33
function reactor_optimizing_plot(ylabel::String; map=:berlin)
	unit = (occursin("Flow", ylabel) ? " (kmol/hr)" : "")
	fig = Figure(size=(700, 500))
	ax = Axis3(fig[1, 1], aspect = (1, 1, 1), title = ylabel*unit,
		xlabel=column_names[2]*"\n(°C)", ylabel=column_names[3]*"\n(kPa)", zlabel=ylabel*unit, xlabeloffset=40, ylabeloffset=45, zlabeloffset=70)
	x = [i for i in reactor_optimizing_data[:, column_names[2]]]
	y = [i for i in reactor_optimizing_data[:, column_names[3]]]
	z = [i for i in reactor_optimizing_data[:, ylabel]]
	h = [i for i in reactor_optimizing_data[:, column_names[4]]]
	scatter!(ax,
		x,
		y,
		z,
		color = h,
		colormap = map
	)
	Colorbar(fig[1, 2], limits = (minimum(h), maximum(h)), colormap = map, flipaxis = false, label = column_names[4])
	return display(fig)
end

# ╔═╡ 5b6236be-ecd4-41ff-8fa1-426feb25aa16
function filter_tube_lengths(length::Float64)
	@assert any(x -> x == length, unique(reactor_optimizing_data[:, "BWR - Tube Length"]))
	df = filter(row -> row."BWR - Tube Length" == length, reactor_optimizing_data)
	fig = Figure(size = (1600, 900))
	Label(fig[0, 2], "Reactor Results for Tube Length : $length m", fontsize = 30, font=:bold)
	x = [i for i in df[:, column_names[2]]]
	y = [i for i in df[:, column_names[3]]]
	h = [i for i in df[:, "BWR - Tube Length"]]
	@assert size(unique(h)) == (1,)

	for (i, ylabel) in enumerate(column_names[5:end])
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
				xlabel=column_names[2]*"\n(°C)", ylabel=column_names[3]*"\n(kPa)", zlabel=chem*unit, xlabeloffset=35, ylabeloffset=40, zlabeloffset=80)
		else
			ax = Axis3(fig[2, i-3], aspect = (1, 1, 1), title = ylabel,
				xlabel=column_names[2]*"\n(°C)", ylabel=column_names[3]*"\n(kPa)", zlabel=chem*unit, xlabeloffset=25, ylabeloffset=40, zlabeloffset=80)
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

# ╔═╡ 7e6da3bc-1f24-4d5d-9557-876d0595bf66
md"# Plotting Case Study Results"

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
md""" ## Specified Tube Length (All Parameters)"""

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
md""" ## Specified Parameter (All Tube Lengths)"""

# ╔═╡ caf489af-5b65-4344-be1a-ba2e03786ac5
if favourite_function == "Specified Parameter (All Tube Lengths)"
	@bind parameter Select(column_names[5:end])
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

# ╔═╡ Cell order:
# ╠═ff3a0990-1f25-11f0-0c4a-4388fb2af02c
# ╠═468a0773-0e66-44a3-b81a-d15393e91929
# ╟─0977b256-ef1a-41f4-9aea-f723ddc576de
# ╟─d447c788-66e6-462a-8103-edde30e1361f
# ╟─94980f0b-010e-4b6b-b21d-ac5fbd372936
# ╟─50bd288b-ab0d-42d3-89a7-2fbf672f2a33
# ╟─5b6236be-ecd4-41ff-8fa1-426feb25aa16
# ╟─7e6da3bc-1f24-4d5d-9557-876d0595bf66
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
