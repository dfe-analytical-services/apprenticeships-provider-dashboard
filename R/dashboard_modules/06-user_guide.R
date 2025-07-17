user_guide <- function() {
  div(
    h1("User guide and definitions"),
    h2("User guide"),
    p("This interactive tool shows data on apprenticeship starts, enrolments and achievements by providers, for
            the latest three years. Use the navigation filters on each page to switch between starts, enrolments and
            achievements. Further filters are available to select academic year, level, age, subject, provider and
            geographical breakdowns. Provider tables can be sorted either alphabetically or by the measure selected."),
    h2("Definitions"),
    h3("Apprenticeships"),
    p("Apprenticeships are paid jobs that incorporate on-the-job and off-the-job training leading to nationally
            recognised qualifications. As an employee, apprentices earn as they learn and gain practical skills in the
            workplace. Apprentices can be new or current employees. Apprenticeships take 1 to 5 years to complete
            depending on their level. Following a review and consultation on the future of apprenticeships in England,
            the government announced reforms to apprenticeships in October 2013. As part of these reforms, new
            employer-led apprenticeship standards were introduced in 2014 to replace the existing frameworks.
            Apprenticeship standards tend to be longer in duration than frameworks, with more off-the job training and
            a rigorous end-point assessment. Apprenticeship frameworks were withdrawn to new learners on 31 July 2020,
            however a small number of framework starts are recorded after this date in situations where it has been
            agreed a learner can return to a framework after an extensive break."),
    h3("Apprenticeship starts"),
    p("Starts are a count of the number of apprenticeships that begin within an academic year (for final data) or
            by the end of the latest quarter (provisional data). They provide the latest information on the take-up of
            apprenticeship programmes. An apprentice is counted for each apprenticeship they start and therefore may
            be counted more than once in the number of starts for each academic year."),
    h3("Apprenticeship enrolments"),
    p("Enrolments are a count of the total number of apprenticeship learning aims undertaken at any point during
            the year. An apprentice is counted for each apprenticeship they undertake and therefore may be counted
            more than once in the number of enrolments for each academic year. However, multiple programmes of study
            by a learner on the same apprenticeship are counted only once."),
    h3("Apprenticeship achievements"),
    p("Achievements are a count of successfully completed apprenticeships within an academic year (for final
            data) or by the end of the latest quarter (provisional data). Learners are counted for each apprenticeship
            they achieve and may be counted more than once in the number of achievements for each academic year. This
            measure is therefore a count of all achievements rather than individual learners. Apprenticeship
            achievements are recorded when a learner reaches the end point of their assessment and not at the end of
            learning. ")
  )
}
