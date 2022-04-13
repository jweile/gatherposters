#!/usr/bin/env Rscript

options(stringsAsFactors=FALSE)

abstractTable <- read.csv(commandArgs(TRUE)[[1]])
# abstractTable <- read.csv('MSS22 Poster abstract submission (Responses) - Form Responses 1.csv')

attendanceTable <- read.csv(commandArgs(TRUE)[[2]])
# attendanceTable <- read.csv('MSS22 Attendance survey (Responses) - Form responses 1.csv')
attendance <- setNames(attendanceTable[,3],attendanceTable[,2])
abstractTable$attInPerson <- attendance[abstractTable$Email.Address]
abstractTable$attInPerson[is.na(abstractTable$attInPerson)] <- "No response"



#escape latex command characters
escape <- function(strs) {
  strs <- trimws(strs)
  strs <- gsub("#","\\#",strs,fixed=TRUE)
  strs <- gsub("%","\\%",strs,fixed=TRUE)
  strs <- gsub("","",strs,fixed=TRUE)
  strs <- gsub(" "," ",strs,fixed=TRUE)
  strs <- gsub("‐","-",strs,fixed=TRUE)
  strs <- gsub("●","$\\cdot$",strs,fixed=TRUE)
  strs <- gsub("~","$\\sim$",strs,fixed=TRUE)
  strs <- gsub("α","$\\alpha$",strs,fixed=TRUE)
  strs <- gsub("β","$\\beta$",strs,fixed=TRUE)
  strs <- gsub("γ","$\\gamma$",strs,fixed=TRUE)
  strs <- gsub("δ","$\\delta$",strs,fixed=TRUE)
  strs <- gsub("Δ","$\\Delta$",strs,fixed=TRUE)
  strs <- gsub("ρ","$\\rho$",strs,fixed=TRUE)
  strs <- gsub("","$\\uparrow$",strs,fixed=TRUE)
  strs <- gsub("","$\\pm$",strs,fixed=TRUE)
  strs <- gsub("_","$\\_$",strs,fixed=TRUE)
  strs <- gsub("&","\\&",strs,fixed=TRUE)
  strs <- gsub("[","{[}",strs,fixed=TRUE)
  strs <- gsub("]","{]}",strs,fixed=TRUE)
  strs <- gsub("^","\\textasciicircum",strs,fixed=TRUE)
  # strs <- gsub("\\[\\d+\\]")
  strs <- gsub("\n","\\\\  ",strs,fixed=TRUE)
  strs
}
abstractTable$Author.list <- escape(abstractTable$Author.list)
abstractTable$Author.affiliations <- escape(abstractTable$Author.affiliations)
abstractTable$Poster.Title <- escape(abstractTable$Poster.Title)
abstractTable$Abstract.text <- escape(abstractTable$Abstract.text)
abstractTable$Keywords <- escape(abstractTable$Keywords)

#latex header and footer
header <- '\\documentclass[12pt]{article}
\\usepackage[letterpaper, margin=2cm]{geometry}
\\usepackage[x11names]{xcolor}
\\usepackage[utf8x]{inputenc}
\\setlength{\\parindent}{0em}
\\setlength{\\parskip}{1em}
\\begin{document}
'
footer <- '\\end{document}'

#assemble content
content <- sapply(1:nrow(abstractTable),function(i) with(abstractTable[i,],{
  paste(
    sprintf("\\section*{%s}",Poster.Title),
    sprintf("\n\n%s\n\n",Author.list),
    sprintf("\n\n{\\scriptsize %s}\n\n",Author.affiliations),
    sprintf("\n\n%s\n\n",Abstract.text),
    sprintf("\n\nKeywords: %s\n\n",Keywords),  
    sprintf("\\textbf{Presenter:} %s (%s, %s)\\\\",Presenter.Name, Presenter.s.Role, Presenter.s.Institution),
    sprintf("\\textbf{Submitted on:} %s\\\\",Timestamp),
    sprintf("\\textbf{Platform talk:} %s\\\\",Would.you.like.your.abstract.to.be.considered.for.a.platform.talk.),
    sprintf("\\textbf{In person:} %s\\\\",attInPerson),
    "\\pagebreak"
  )
}))

#write header, content, and footer to latex file
con <- file("abstracts.tex",open="w")
writeLines(c(header,content,footer),con=con)
close(con)

#compile latex to pdf
retVal <- system("pdflatex -halt-on-error abstracts")

notAttributable <- setdiff(names(attendance),abstractTable$Email.Address)
if (length(notAttributable) > 0) {
  cat("Non-attributable email address(es):\n")
  cat(paste(sprintf(" * %s : %s",notAttributable,attendance[notAttributable]),collapse="\n"),"\n")
}

#cleanup (if compilation was successful)
if (retVal == 0) {
  file.remove(c("abstracts.aux","abstracts.log","abstracts.tex"))
}