[![Automated tests](https://github.com/dfe-analytical-services/apprenticeships-provider-dashboard/actions/workflows/automated-tests.yaml/badge.svg)](https://github.com/dfe-analytical-services/apprenticeships-provider-dashboard/actions/workflows/automated-tests.yaml)
[![shinyapps.io deploy](https://github.com/dfe-analytical-services/apprenticeships-provider-dashboard/actions/workflows/deploy-shiny.yaml/badge.svg)](https://github.com/dfe-analytical-services/apprenticeships-provider-dashboard/actions/workflows/deploy-shiny.yaml)
[![Build Status](https://dfe-gov-uk.visualstudio.com/official-statistics-production/_apis/build/status%2Fdfe-analytical-services.apprenticeships-provider-dashboard?repoName=dfe-analytical-services%2Fapprenticeships-provider-dashboard&branchName=main)](https://dfe-gov-uk.visualstudio.com/official-statistics-production/_build/latest?definitionId=1393&repoName=dfe-analytical-services%2Fapprenticeships-provider-dashboard&branchName=main)

# Apprencticeships provider dashboard

## Introduction 

<!-- Give a brief overview of what your app is for here.-->

...

This application is deployed in the following places, access is restricted during the development phase:

- shinyapps.io testing - https://department-for-education.shinyapps.io/apprenticeships-provider-dashboard/

- Internal testing (production) - https://rsconnect/rsc/apprenticeships-provider-dashboard/
- Internal testing (pre-production) - https://rsconnect-pp/rsc/apprenticeships-provider-dashboard/

---

## Requirements

The following requirements are necessarily for running the application yourself or contributing to it.

### i. Software requirements (for running locally)

- Installation of R Studio 2024.04.2+764 "Chocolate Cosmos" or higher

- Installation of R 4.4.1 or higher

- Installation of RTools44 or higher

### ii. Programming skills required (for editing or troubleshooting)

- R at an intermediate level, [DfE R leanring resources](https://dfe-analytical-services.github.io/analysts-guide/learning-development/r.html)

- Particularly [R Shiny](https://shiny.rstudio.com/) and [Shiny modules](https://mastering-shiny.org/scaling-modules.html)

### iii. Access requirements

No additional requirements - all data needed to run the app and dependencies are available in the repo.

---

## How to use

<!-- Add any other useful detail for others about your application code here -->

...

### Running the app locally

1. Clone or download the repo. 

2. Open the R project in R Studio.

3. Run `renv::restore()` to install dependencies.

4. Run `shiny::runApp()` to run the app locally.

### Folder structure

All R code outside of the core `global.R`, `server.R`, and `ui.R` files is stored in the `R/` folder. The `ui.R.` and `server.R` can stay mostly static with most of the code being held in separate modules in the `R/dashboard_modules/` folder or as content for pages linked from the footer in `R/footer_pages/`.

- `R/helper_functions.R` file for common custom functions.
- `R/read_data.R` creates the functions used to read data into the app.
- Scripts for the different UI panels in the `R/dashboard_modules/` folder. 
- Scripts for the pages linked from the footer in the `R/footer_pages/` folder.
- Data used by the app is stored in the `data/` folder.

There is a `R/data-prep/` folder, this contains scripts not used by the app, that are used separately to prepare the data saved in the `data/` folder in tandem with the original SQL scripts are saved in the `sql/` folder.

### Data

The data used in this app is too large in CSV format to be stored in a Git repo. As a result we have used the [parquet](https://parquet.apache.org/) format from Apache. The `R/data-prep/create_data_files.R` script takes in CSVs generated from the SQL queries and then creates .parquet versions for use in the app.

This leads to using the [arrow package](https://arrow.apache.org/docs/r/) for data reading and manipulation and provides many performance benefits.

#### File sizes

There is a bonus script `R/data-prep/check_file_sizes.R` that can be used to test the maximum potential file download sizes, so that we can then hard code that information into the UI for radio button options changing the file type for end users.

### Packages

Package control is handled using renv. As in the steps above, you will need to run `renv::restore()` if this is your first time using the project.

Whenever you add new packages, make sure to use `renv::snapshot()` to record them in the `renv.lock` file.

### Pre-commit hooks

There are a number of pre-commit hooks that will execute every time you commit to the app, these are set in the `.hooks/pre-commit.R` script and are:

1. Check for any non-declared or unpublished data
2. Check the template Google Analytics ID isn't present
3. Checking the styling of code using `styler::style_dir()`
4. Generating the `manifest.json` file that is used for deploying to POSIT Connect internally

Should they fail or prevent you committing they will give their reasons in error / warning messages along with steps to take to remedy the issue.

### Tests

Automated tests have been created using shinytest2 that test the app loads and also give other examples of ways you can use tests. You should edit the tests as you add new features into the app and continue to add and maintain the tests over time.

GitHub Actions provide CI by running the automated tests and checks for code styling on every pull request into the main branch. The yaml files for these workflows can be found in the .github/workflows folder.

You should run `shinytest2::test_app()` regularly to check that the tests are passing against the code you are working on.

### Deployment

The app is deployed to Department for Education's shinyapps.io subscription and internal POSIT Connect servers using GitHub actions. The yaml files for this are `.github/workflows/deploy-shiny.yml` and `azure-pipelines.yml`. Maintenance of this is provided by the Explore education statistics platforms team.

### Navigation

In general all .r files will have a usable outline, so make use of that for navigation if in RStudio: `Ctrl-Shift-O`.

### Code styling 

The function `styler::style_dir()` will tidy code according to tidyverse styling using the styler package. Run this regularly as only tidied code will be allowed to be committed. This function also helps to test the running of the code and for basic syntax errors such as missing commas and brackets.

You should also run `lintr::lint_dir()` regularly as lintr will check all pull requests for the styling of the code, it does not style the code for you like styler, but is slightly stricter and checks for long lines, variables not using snake case, commented out code and undefined objects amongst other things.

---

## How to contribute

Always run the following commands before raising changes:

- `styler::style_dir()` - to format the code neatly
- `lintr::lint_dir()` - to check for any potential issues with code formatting
- `shinytest2::test_app()` - to run automated tests again the app

### Flagging issues

If you spot any issues with the application, please flag it in the "Issues" tab of this repository, and label as a bug. Include as much detail as possible to help the developers diagnose the issue and prepare a suitable remedy.

### Making suggestions

You can also use the "Issues" tab in GitHub to suggest new features, changes or additions. Include as much detail on why you're making the suggestion and any thinking towards a solution that you have already done.

---

## Contact

fe.officialstatistics@education.gov.uk and explore.statistics@education.gov.uk
