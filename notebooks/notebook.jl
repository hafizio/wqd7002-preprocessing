### A Pluto.jl notebook ###
# v0.14.2

using Markdown
using InteractiveUtils

# ╔═╡ 1f98610c-52a0-11eb-36a8-59dedc786f2f
begin
	import Pkg
	
	Pkg.add("CSV")
	Pkg.add("JSON")
	Pkg.add("DataFrames")
	Pkg.add("DataFramesMeta")
	Pkg.add("Dates")
	Pkg.add("StatsPlots")
	
	using CSV
	using JSON
	using DataFrames
	using DataFramesMeta
	using Dates
	using StatsPlots
	using Statistics
end

# ╔═╡ ad101922-52a4-11eb-0e9a-ad57cd3d295d
begin
	# f = open("../../wqd7002-web-scraper/output/response-sg-my.jl")
	f = open("../../wqd7002-web-scraper/output/response-au-copy.jl")
	lines = readlines(f)
	close(f)
end

# ╔═╡ 343da3b2-5e29-11eb-3398-5d4f4fc1e755
sample = JSON.parse(lines[10])

# ╔═╡ b8f687dc-5310-11eb-2bbf-39781287d217
sampleJobPosting = JSON.parse(lines[10])["jobPosting"]

# ╔═╡ 5c2e28be-5303-11eb-1d34-63ce6bffea19
function get_salary_range(raw_salary_range)
	pat = r"[+]?\d+\.?\d*"
	
	salary_range = replace(raw_salary_range, [',',';',' '] => "")
	
	println(salary_range)

	numbers = map(findall(pat, salary_range)) do range
		if occursin("year", raw_salary_range)
    		parse(Float64, salary_range[range])/12
		elseif occursin("Annum", raw_salary_range)
    		parse(Float64, salary_range[range])/12
		else
			monthly_salary = parse(Float64, salary_range[range])
			
			# we assume that the company forgot to define that it's a yearly value
			if monthly_salary > 100000.0
				parse(Float64, salary_range[range])/12
			elseif monthly_salary == 1.0
				1000.0
			else
				monthly_salary
			end
		end
	end
end

# ╔═╡ bfec4d7c-5317-11eb-1d8d-2f860d8115e8
a = replace("Salary RM 1 999 - 2 000 per month", [',',';', ' '] => "")

# ╔═╡ 5eaa80ce-5317-11eb-132e-712f41da8a4f
get_salary_range(a)

# ╔═╡ 1ef2fd9a-531b-11eb-3a1e-9f7e43e5ba39
function get_country_from_url(url)
	if occursin("malaysia", url)
		"MY"
	elseif occursin("sg", url)
		"SG"
	elseif occursin("au", url)
		"AU"
	else
		println(url)
		missing
	end
end

# ╔═╡ 7a4a621a-5333-11eb-258e-dbe323807ae9
function get_year_from_date_posted(date_posted)
	t = DateTime("2021-01-30T00:00:00")
	year = Dates.format(t, "yyyy")
	parse(Int, year)
end

# ╔═╡ 0bbbc202-533e-11eb-1ae1-e3af8a0061dc
function standardize_currency(country, salary_currency)
	if ismissing(country)
		println("Missing")
		missing
	elseif country == "MY"
		if occursin("RM", salary_currency)
			"MYR"
		elseif occursin("MYR", salary_currency)
			"MYR"
		else
			missing
		end
	elseif country == "SG"
		if occursin("\$", salary_currency)
			"SGD"
		elseif occursin("SGD", salary_currency)
			"SGD"
		else
			missing
		end
	elseif country == "AU"
		if occursin("\$", salary_currency)
			"AUD"
		elseif occursin("AUD", salary_currency)
			"AUD"
		else
			missing
		end
	else
		missing
	end
end

# ╔═╡ 0e218b28-531c-11eb-2a77-ed9f5d165abe
occursin("malaysia", "https://malaysia.indeed.com/")

# ╔═╡ a7d40214-5343-11eb-2ccf-13f176459222
occursin("Annum", "SGD\$70,000 - SGD\$90,000/Annum")

# ╔═╡ f12a8eb4-5347-11eb-08b9-9b6c6d589496
"MYR" == "MYR"

# ╔═╡ 656f6f42-5348-11eb-0836-cf0a7da996f8
missing | true

# ╔═╡ 9403c0de-5347-11eb-18c7-99c7109d7390
function convert_salary(original_currency, salary_amount)
	if ismissing(original_currency)
		missing
	elseif original_currency == "MYR"
		salary_amount
	elseif original_currency == "SGD"
		# currency conversion from SGD 1 to MYR 
		salary_amount * 3.04
	elseif original_currency == "AUD"
		# currency conversion from AUD 1 to MYR
		salary_amount * 3.12
	end
end

# ╔═╡ 2f49df5c-5301-11eb-1310-95202f53809c
job_postings = map(lines) do line
	# main posting
	posting = get(JSON.parse(line), "jobPosting", Dict())
	
	# url
	url = get(posting, "url", "")

	# country
	country = get_country_from_url(url)
		
	# salary
	salary = get(posting, "baseSalary", Dict())
	# println(salary)
	salary_range = get_salary_range(get(salary, "raw", "0-0"))
	# println(salary_range)
	salary_min = first(salary_range)
	salary_max = last(salary_range)
	
	# salary currency
	salary_currency = get(salary, "currency", "")
	# println(salary_currency)
	std_salary_currency = standardize_currency(country, salary_currency)
	# println(std_salary_currency)

	# location
	location = get(posting, "jobLocation", Dict())
	
	# company
	company = get(posting, "hiringOrganization", Dict())
	
	# year posted
	date = get(posting, "datePosted", "")
	year_posted = get_year_from_date_posted(date)
	
	Dict(
		"url" => url,
		"title" => get(posting, "title", missing),
		"city" => get(location, "raw", missing),
		"country" => country,
		"year_posted" => year_posted,
		"salary_raw" => get(salary, "raw", missing),
		"salary_currency" => std_salary_currency,
		"salary_min" => salary_min,
		"salary_max" => salary_max,
		"salary_converted_currency" => "MYR",
		"salary_converted_min" => convert_salary(std_salary_currency, salary_min),
		"salary_converted_max" => convert_salary(std_salary_currency, salary_max),
		"company" => get(company, "raw", missing),
		"description" => get(posting, "description", missing)
	)
end

# ╔═╡ baf9a4f2-5337-11eb-0c0e-bf767eb4df6e
df_job_postings = reduce(vcat, DataFrame.(job_postings))

# ╔═╡ 82bc1fec-5301-11eb-16e5-fb00b6889765
# open("response.json", "w") do f
# 	JSON.print(f, job_postings)
# end

# ╔═╡ 18158f3a-5332-11eb-3be7-c9629756536f
df_job_posting_with_salary = dropmissing(df_job_postings, :salary_raw)

# ╔═╡ 706ddfca-5341-11eb-3c6c-3578496f2e94
minimum(df_job_posting_with_salary[!,:salary_max])

# ╔═╡ 2091138c-5341-11eb-3030-612fe5117951
maximum(df_job_posting_with_salary[!,:salary_max])

# ╔═╡ 211db4d6-5341-11eb-04f0-0ba25f95b60e
minimum(df_job_posting_with_salary[!,:salary_min])

# ╔═╡ 76855ec4-5341-11eb-1d28-8bcffef990b6
maximum(df_job_posting_with_salary[!,:salary_min])

# ╔═╡ 4ad5cf56-5345-11eb-11a4-ab9171520910
mean(df_job_posting_with_salary[!,:salary_min])

# ╔═╡ 98c68b08-5345-11eb-3733-cdfbce561bbc
mean(df_job_posting_with_salary[!,:salary_max])

# ╔═╡ 213049c4-5342-11eb-3333-63e959f6f7ae
@where(df_job_posting_with_salary, in([30000.0]).(:salary_max))

# ╔═╡ 266b6b2a-5343-11eb-3dc0-430b249e7f84
@where(df_job_posting_with_salary, in([70000.0]).(:salary_min))

# ╔═╡ 3486a1a8-5338-11eb-0277-492beda3e54c
begin
	gr(size=(900,900))
	
	@df df_job_posting_with_salary scatter(
	    :salary_converted_min,
	    :salary_converted_max,
	    group = :country,
	)
end

# ╔═╡ 0af6dc82-5346-11eb-3708-534b25be53c3
CSV.write("../output/job_posting_with_salary.csv", df_job_posting_with_salary)

# ╔═╡ Cell order:
# ╠═1f98610c-52a0-11eb-36a8-59dedc786f2f
# ╠═ad101922-52a4-11eb-0e9a-ad57cd3d295d
# ╠═343da3b2-5e29-11eb-3398-5d4f4fc1e755
# ╠═b8f687dc-5310-11eb-2bbf-39781287d217
# ╠═5c2e28be-5303-11eb-1d34-63ce6bffea19
# ╠═bfec4d7c-5317-11eb-1d8d-2f860d8115e8
# ╠═5eaa80ce-5317-11eb-132e-712f41da8a4f
# ╠═1ef2fd9a-531b-11eb-3a1e-9f7e43e5ba39
# ╠═7a4a621a-5333-11eb-258e-dbe323807ae9
# ╠═0bbbc202-533e-11eb-1ae1-e3af8a0061dc
# ╠═0e218b28-531c-11eb-2a77-ed9f5d165abe
# ╠═a7d40214-5343-11eb-2ccf-13f176459222
# ╠═f12a8eb4-5347-11eb-08b9-9b6c6d589496
# ╠═656f6f42-5348-11eb-0836-cf0a7da996f8
# ╠═9403c0de-5347-11eb-18c7-99c7109d7390
# ╠═2f49df5c-5301-11eb-1310-95202f53809c
# ╠═baf9a4f2-5337-11eb-0c0e-bf767eb4df6e
# ╠═82bc1fec-5301-11eb-16e5-fb00b6889765
# ╠═18158f3a-5332-11eb-3be7-c9629756536f
# ╠═706ddfca-5341-11eb-3c6c-3578496f2e94
# ╠═2091138c-5341-11eb-3030-612fe5117951
# ╠═211db4d6-5341-11eb-04f0-0ba25f95b60e
# ╠═76855ec4-5341-11eb-1d28-8bcffef990b6
# ╠═4ad5cf56-5345-11eb-11a4-ab9171520910
# ╠═98c68b08-5345-11eb-3733-cdfbce561bbc
# ╠═213049c4-5342-11eb-3333-63e959f6f7ae
# ╠═266b6b2a-5343-11eb-3dc0-430b249e7f84
# ╠═3486a1a8-5338-11eb-0277-492beda3e54c
# ╠═0af6dc82-5346-11eb-3708-534b25be53c3
