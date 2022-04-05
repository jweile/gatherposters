#!/usr/bin/env Rscript

options(stringsAsFactors=FALSE)

abstractTable <- read.csv(commandArgs(TRUE)[[1]])
# abstractTable <- read.csv('MSS22 Poster abstract submission (Responses) - Form Responses 1.csv')

#escape latex command characters
escape <- function(strs) {
  strs <- trimws(strs)
  strs <- gsub("#","\\#",strs,fixed=TRUE)
  strs <- gsub("%","\\%",strs,fixed=TRUE)
  strs <- gsub("","",strs,fixed=TRUE)
  strs <- gsub(" "," ",strs,fixed=TRUE)
  strs <- gsub("α","$\\alpha$",strs,fixed=TRUE)
  strs <- gsub("β","$\\beta$",strs,fixed=TRUE)
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
    "\\pagebreak"
  )
}))

#write header, content, and footer to latex file
con <- file("abstracts.tex",open="w")
writeLines(c(header,content,footer),con=con)
close(con)

#compile latex to pdf
retVal <- system("pdflatex -halt-on-error abstracts")

#cleanup (if compilation was successful)
if (retVal == 0) {
  file.remove(c("abstracts.aux","abstracts.log","abstracts.tex"))
}