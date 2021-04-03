### A Pluto.jl notebook ###
# v0.12.18

using Markdown
using InteractiveUtils

# ╔═╡ f387b6c6-5329-11eb-2e26-0321b12d7286
begin
	import Pkg

	Pkg.add("DataFrames")
	Pkg.add("CSV")
	Pkg.add("StatsPlots")
	
	using DataFrames
	using CSV
	using StatsPlots
end

# ╔═╡ 1d6ae802-532a-11eb-370b-33068dc87e37
job_posting = CSV.read("./job_postings_normalized.csv", DataFrame)

# ╔═╡ 0c7736d0-532b-11eb-1713-1967e9d88659
job_posting_with_salary = dropmissing(job_posting, :salary_raw)

# ╔═╡ b4301928-5335-11eb-0783-fb339c82e7f0
maximum(job_posting_with_salary[!,:salary_min])

# ╔═╡ 21c7bcf4-532f-11eb-14b9-c986d76b2072
begin
	gr(size=(1000,1000))
	
	@df job_posting_with_salary scatter(
	    :salary_min,
	    :salary_max,
	    group = :salary_currency,
	)
end

# ╔═╡ Cell order:
# ╠═f387b6c6-5329-11eb-2e26-0321b12d7286
# ╠═1d6ae802-532a-11eb-370b-33068dc87e37
# ╠═0c7736d0-532b-11eb-1713-1967e9d88659
# ╠═b4301928-5335-11eb-0783-fb339c82e7f0
# ╠═21c7bcf4-532f-11eb-14b9-c986d76b2072
