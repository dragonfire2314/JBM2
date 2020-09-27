import xlsxwriter, json
import numpy as np

book = xlsxwriter.Workbook("test.xlsx")
sheet = book.add_worksheet("problem summaries")

bold_format = book.add_format({'bold': True, 'align': 'right'})
impgen_format = book.add_format({'align': 'center', 'bg_color': '#CCFFFF', 'border_color': 'black', 'border': 1})
solution_format = book.add_format({'bg_color': '#85ffa', 'border_color': 'black', 'border': 1})

dataset = json.loads(open("../results/quick_res.json").read())
dataset.sort(key=lambda x: x["problem"]["dataset"]*100 + x["problem"]["instance"]*10
    + x["problem"]["case"])

def add_impgens(sheet, ig, row, col):
    sheet.write(row, col, "Improvement Generations: ", bold_format)
    col += 2
    sheet.write(row, col, "Time:", bold_format)
    sheet.write(row+1, col, "Applications:", bold_format)
    sheet.write(row+2, col, "Score:", bold_format)
    start_time = ig[0][0]
    for (i, time_gen_score) in enumerate(ig):
        sheet.write(row, col+1+i, time_gen_score[0] - start_time, impgen_format)
        sheet.write(row+1, col+1+i, time_gen_score[1], impgen_format)
        sheet.write(row+2, col+1+i, time_gen_score[2], impgen_format)
    return row + 3, col + len(ig)

def add_top_sols(sheet, pop, row, col, n=5):
    sheet.write(row, col, "Top Solutions:", bold_format)
    col += 1
    pop.sort(key=lambda x: -int(x[0]))
    for i in range(n):
        sheet.write(row, col, pop[i][0], solution_format)
        sheet.write(row, col+1, pop[i][1], solution_format)
        row += 1
    return row, col + 1

def add_id(sheet, problem, row, col):
    sheet.write(row, col, "D/I/C:", bold_format)
    sheet.write(row, col + 1, str(problem["dataset"]) + "/" + str(problem["instance"]) + "/" + str(problem["case"]))
    return row+1, col+1

def add_opt_params(sheet, params, row, col):
    sheet.write(row, col, "Optimizer Params:", bold_format)
    sheet.write(row, col+1, str(params))
    return row + 1, col + 1

row = 0
col = 0
for result in dataset:
    print(result.keys())
    row, col = add_id(sheet, result["problem"], row, 0)
    row, col = add_impgens(sheet, result["imp_gens"], row, 0)
    row, col = add_top_sols(sheet, result["pop"], row, 0)
    row, col = add_opt_params(sheet, result["optimizer"], row, 0)
    row += 1
    col = 0

book.close()

#------------------------------------------------------------summary section
# for meta_family in ["Rao1", "Rao2"]:
#     summary_sheet = book.add_sheet(meta_family + " Summary Tables")
#     summary_sheet.add_big_title(meta_family + " Summary Tables", 36)
#     summary_sheet.new_section("All Results")
#
#     all_results = result_formatter.extract_table(
#         trialset,
#         {"metaheuristic": "Rao1"},
#         ["popsize", "n_param", "local_search"],
#         ["metaheuristic"])
#     mean_table = result_formatter.summarize(all_results, result_formatter.ts_mean)
#     summary_sheet.add_table(mean_table, title="Averages", headers=all_headers(book.percentage_format))
#     std_table = result_formatter.summarize(all_results, result_formatter.ts_std)
#     summary_sheet.add_table(std_table, title="Standard Deviations", headers=all_headers(book.percentage_format))
#     invalid_table = result_formatter.summarize(all_results, result_formatter.ts_invalid)
#     summary_sheet.add_table(invalid_table, title="Total Invalid", headers=all_headers(book.default_format))
#
#     summary_sheet.new_section("Per Dataset")
#     ds_results = result_formatter.extract_table(
#         trialset,
#         {"metaheuristic": "Rao1"},
#         ["popsize", "n_param", "local_search"],
#         ["dataset"])
#     mean_table = result_formatter.summarize(ds_results, result_formatter.ts_mean)
#     summary_sheet.add_table(mean_table, title="Dataset Means", headers=ds_headers(book.percentage_format))
#     std_table = result_formatter.summarize(ds_results, result_formatter.ts_std)
#     summary_sheet.add_table(std_table, title="Dataset Standard Deviations", headers=ds_headers(book.percentage_format))
#     invalid_table = result_formatter.summarize(ds_results, result_formatter.ts_invalid)
#     summary_sheet.add_table(invalid_table, title="Dataset Averages", headers=ds_headers(book.default_format))
#
#
#     summary_sheet.new_section("Per Case")
#     case_results = result_formatter.extract_table(
#         trialset,
#         {"metaheuristic": "Rao1"},
#         ["popsize", "n_param", "local_search"],
#         ["case"])
#     mean_table = result_formatter.summarize(case_results, result_formatter.ts_mean)
#     summary_sheet.add_table(mean_table, title="Case Means", headers=case_headers(book.percentage_format))
#     std_table = result_formatter.summarize(case_results, result_formatter.ts_std)
#     summary_sheet.add_table(std_table, title="Case Standard Deviations", headers=case_headers(book.percentage_format))
#     invalid_table = result_formatter.summarize(case_results, result_formatter.ts_invalid)
#     summary_sheet.add_table(invalid_table, title="Case Averages", headers=case_headers(book.default_format))
#
#     summary_sheet.new_section()

#cleanup
