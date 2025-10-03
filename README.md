[![Automated tests](https://github.com/dfe-analytical-services/apprenticeships-provider-dashboard/actions/workflows/automated-tests.yaml/badge.svg)](https://github.com/dfe-analytical-services/apprenticeships-provider-dashboard/actions/workflows/automated-tests.yaml)
[![shinyapps.io deploy](https://github.com/dfe-analytical-services/apprenticeships-provider-dashboard/actions/workflows/deploy-shiny.yaml/badge.svg)](https://github.com/dfe-analytical-services/apprenticeships-provider-dashboard/actions/workflows/deploy-shiny.yaml)
[![Build Status](https://dfe-gov-uk.visualstudio.com/official-statistics-production/_apis/build/status%2Fdfe-analytical-services.apprenticeships-provider-dashboard?repoName=dfe-analytical-services%2Fapprenticeships-provider-dashboard&branchName=main)](https://dfe-gov-uk.visualstudio.com/official-statistics-production/_build/latest?definitionId=1393&repoName=dfe-analytical-services%2Fapprenticeships-provider-dashboard&branchName=main)

# Apprencticeships provider dashboard

## Introduction 

A prototype dashboard for exploring further education provider data.

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

- R at an intermediate level, [DfE R learning resources](https://dfe-analytical-services.github.io/analysts-guide/learning-development/r.html)

- Particularly [R Shiny](https://shiny.rstudio.com/), [reactivity](https://mastering-shiny.org/basic-reactivity.html) and [Shiny modules](https://mastering-shiny.org/scaling-modules.html)

### iii. Access requirements

No additional requirements - all data needed to run the app and dependencies are available in the repo.

To update the data in the repo you will need access to the underlying databases. 

---

## How to use

### Running the app locally

1. Clone or download the repo. 

2. Open the R project in R Studio.

3. Run `renv::restore()` to install dependencies.

3a. If renv operations doesn't complete does not complete / has errors due to retired libraries Run `renv::record("[library_name]@20.0.0.2")`  e.g. renv::record("arrow@20.0.0.2")

3b. Restart R environment session - Ctrl + Shift + F10

4. Run `shiny::runApp()` to run the app locally.

5. Run `shinytest2::test_app()` to run the tests against the app.

If you run all of that successfully you're cooking with gas! Commit changes 

### Folder structure

All R code outside of the core `global.R`, `server.R`, and `ui.R` files is stored in the `R/` folder. The `ui.R.` and `server.R` can stay mostly static with most of the code being held in separate modules in the `R/dashboard_modules/` folder or as content for pages linked from the footer in `R/footer_pages/`.

- `R/helper_functions.R` file for custom functions used in the project.
- Scripts for the different UI panels in the `R/dashboard_modules/` folder. 
- Scripts for the pages linked from the footer in the `R/footer_pages/` folder.
- Data used by the app is stored in the `data/` folder.

There is a `R/data-prep/` folder, this contains scripts not used by the app, that are used separately to prepare the data saved in the `data/` folder in tandem with the original SQL scripts are saved in the `sql/` folder.

Due to the size of the app, every page on it has its own script, for example each interactive dashboard page has it's own `UI` and `Server` component in a module script in the `R/dashboard_modules/` folder. All of the code for each page will be in the module, including:
- reading the data into the app
- what the UI layout looks like what the user inputs are
- what the server side processing looks like for that page

This keeps each page isolated, and hopefully easier to maintain should this expand further!

### Data

The data used in this app is too large in CSV format to be stored in a Git repo. As a result we have used the [parquet](https://parquet.apache.org/) format from Apache. This leads to using the [arrow package](https://arrow.apache.org/docs/r/) for data reading and manipulation and provides many performance benefits.

To update the data you will need to do this manually outside of the app. The `R/data-prep/create_data_files.R` script should be used for this. Follow the instructions in there to run the code against CSVs generated from the SQL queries and this script will then create the .parquet files for use in the app.

#### Location of Databricks CSV file data
The following three SQL datasets (provider data / apprenticeship demographic and apprenticeship) are replace by this code. This code also drives the Power BI dashboard environment (Apps 38 provider dashboard - Databricks)
https://adb-5037484389568426.6.azuredatabricks.net/editor/notebooks/3304709417398768?o=5037484389568426#command/3304709417398769

Further, the apprenticeship demographic file has to be adapted to include padding out of the data. The revised SQL code can be found here:
https://adb-5037484389568426.6.azuredatabricks.net/editor/notebooks/1399051160547519?o=5037484389568426#command/6083354069375510


#### File sizes

There is a bonus script `R/data-prep/check_file_sizes.R` that can be used to test the maximum potential file download sizes, so that we can then hard code that information into the UI for radio button options changing the file type for end users.

#### Boundary files

The boundary files used in the LAD maps are stored in the `data/boundary_files/` folder. They were downloaded from the [Open Geography Portal](https://geoportal.statistics.gov.uk/search?q=BDY_LAD%20UK%20BUC&sort=Date%20Created%7Ccreated%7Cdesc) in GeoPackage format. If you search for 'BDY_LAD UK BUC' you should be able to find the files, as well as any newer or older versions of the boundaries. The following boundaries are used for each year:

- 2021/22: December 2022 boundaries
- 2022/23: May 2023 boundaries
- 2023/24: May 2024 boundaries

### Packages

Package control is handled using renv. As in the steps above, you will need to run `renv::restore()` if this is your first time using the project.

Whenever you add new packages, make sure to use `renv::snapshot()` to record them in the `renv.lock` file.

Whenever library versions are superseded by newer versions (usually when `renv::restore()` fails) run install.packages({library_name}) then Run `renv::record("[library_name]@[version]")`  e.g. renv::record("arrow@20.0.0.2")

### Pre-commit hooks

There are a number of pre-commit hooks that will execute every time you commit to the app, these are set in the `.hooks/pre-commit.R` script and are:

1. Check for any non-declared or unpublished data
2. Check the template Google Analytics ID isn't present
3. Checking the styling of code using `styler::style_dir()`
4. Generating the `manifest.json` file that is used for deploying to POSIT Connect internally

Should they fail or prevent you committing they will give their reasons in error / warning messages along with steps to take to remedy the issue. If there's persistent or confusing issues get in touch with explore.statistics@education.gov.uk.

### Tests

Automated tests have been created using shinytest2 that test the app loads and also give other examples of ways you can use tests. You should edit the tests as you add new features into the app and continue to add and maintain the tests over time. All test scripts can be found within the `tests/testthat/` folder.

There are three types of test used (in increasing levels of complexity / thoroughness):
- Function (take a specific function and check it behaves as expected)
- Server (take a whole server module of the app and check the reactivity works as expected)
- UI (run the full app, interact with the user interface (UI) and then check the outputs)

You should run `shinytest2::test_app()` regularly to check that the tests are passing against the code you are working on.

GitHub Actions provide CI by running the automated tests and checks for code styling on every pull request pointed at the main branch. The yaml files for these workflows can be found in the `.github/workflows` folder. Maintenance of this is provided by the explore education statistics platforms team.

If the tests fail unexpectedly, sometimes just re-running them will help. Testing applications like this is notoriously difficult and every now and then shinytest2 will hiccup and fail to start a port or session running properly, or will just take too long to process something causing a test to fail. 

If there's persistent or confusing issues get in touch with the explore education statistics platforms team who can support with this.

### Deployment

The app is deployed to Department for Education's shinyapps.io subscription and internal POSIT Connect servers using GitHub actions. The yaml files for this are `.github/workflows/deploy-shiny.yml` and `azure-pipelines.yml`. 

Sometimes deployments may fail because they can't find a file. Often this will be due to a quirk of the manifest.json file not ignoring files correctly. If the app doesn't need the file in the error message, simply delete that file and then run `rsconnect::writeManifest()` to update the manifest file and push up a new commit. Maintenance of this is provided by the explore education statistics platforms team, reach out to them if there's any issues with deployments.

### Navigation

In general all .R files will have a usable outline, so make use of that for navigation if in RStudio: `Ctrl-Shift-O`.

### Code styling 

The function `styler::style_dir()` will tidy code according to tidyverse styling using the styler package. Run this regularly as only tidied code will be allowed to be committed. This function also helps to test the running of the code and for basic syntax errors such as missing commas and brackets.

You should also run `lintr::lint_dir()` regularly as lintr will check all pull requests for the styling of the code, it does not style the code for you like styler, but is slightly stricter and checks for long lines, variables not using snake case, commented out code and undefined objects amongst other things.

---

## How to contribute

In general, it is good practice to make specific changes at a time, add one new feature rather than smattering code all over the app. It will make it easier to test, easier to roll back if needed, and also easier for whoever is reviewing your code. Like all good advice, little and often is usually the way to go.

1. Make a new branch for your change based off the `main` branch
2. Make your changes, testing thoroughly and updating documentation as needed

Always run the following commands before raising changes:

- `styler::style_dir()` - to format the code neatly
- `lintr::lint_dir()` - to check for any potential issues with code formatting
- `shinytest2::test_app()` - to run automated tests again the app

3. Raise a pull request on GitHub, with details of the changes you have made
4. Get someone to review your changes, respond to any feedback and make changes on your branch until the reviewer marks the pull request as approved
5. Once your pull request is approved, merge it into the main branch and delete the branch you were working on (we should use a new branch for every new change, reviving old branches can get messy)

### Flagging issues

If you spot any issues with the application, please flag it in the ["Issues" tab of this repository](https://github.com/dfe-analytical-services/apprenticeships-provider-dashboard/issues), and label as a bug. Include as much detail as possible to help the developers diagnose the issue and prepare a suitable remedy.

### Making suggestions

You can also use the ["Issues" tab in GitHub](https://github.com/dfe-analytical-services/apprenticeships-provider-dashboard/issues) to suggest new features, changes or additions. Include as much detail on why you're making the suggestion and any thinking towards a solution that you have already done.

---

## Contact

fe.officialstatistics@education.gov.uk
