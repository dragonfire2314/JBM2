import xlsxwriter, json, os
import numpy as np

book = xlsxwriter.Workbook("test.xlsx")
sheet = book.add_worksheet("problem summaries")

bold_format = book.add_format({'bold': True, 'align': 'right'})
impgen_format = book.add_format({'align': 'center', 'bg_color': '#CCFFFF', 'border_color': 'black', 'border': 1})
solution_format = book.add_format({'bg_color': '#85ffa', 'border_color': 'black', 'border': 1})

dataset = json.loads(open("../results/quick_res.json").read())
dataset.sort(key=lambda x: x["problem"]["dataset"]*100 + x["problem"]["instance"]*10
    + x["problem"]["case"])

def add_step_tolerances(sheet, st, row, col):
    sheet.write(row, col, "Tolerance Increments: ", bold_format)
    col += 2
    sheet.write(row, col, "Tolerance:", bold_format)
    sheet.write(row+1, col, "Objective:", bold_format)
    sheet.write(row+2, col, "Solution status:", bold_format)
    sheet.write(row+3, col, "Termination reason:", bold_format)
    print(len(st))
    for trial_result in st:
        for (i, trial_step) in enumerate(trial_result):
            print(trial_step["tolerance"])
            sheet.write(row, col+1+i, trial_step["tolerance"], bold_format)
            sheet.write(row+1, col+1+i, trial_step["objective"], impgen_format)
            sheet.write(row+2, col+1+i, trial_step["solution_status"], impgen_format)
            sheet.write(row+3, col+1+i, trial_step["termination_status"], impgen_format)

    return (row + 3, col + len(st))

#collect data
all_problems = []
dir = "../math_results"
for file in sorted(os.listdir(dir)):
    print(file)
    data = json.loads(open(os.path.join(dir, file), "r").read())
    all_problems.append(data)

print(all_problems)

row, col = 0, 0
for result in all_problems:
    sheet.write(row, 1, json.dumps(result["problem"]))
    row, col = add_step_tolerances(sheet, result["tolsteps"], row, 0)
    row += 3

book.close()
