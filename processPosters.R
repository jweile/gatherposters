#!/usr/bin/Rscript
options(stringsAsFactors=FALSE)

library(yogilog)
library(yogitools)
logger <- yogilog::new.logger("posters.log")

#helper function to convert a dataframe into an HTML table body
df2html <- function(df) {
	paste(apply(df,1,function(row) {
		paste0("<tr>",paste(sapply(row, function(field) {
			paste0("<td>",field,"</td>")
		}),collapse=" "),"</tr>")
	}),collapse="\n")
}

#helper function to draw text with white "shadow" around it
shadowtext <- function(x, y=NULL, labels, col="black", bg="white", r=0.2, ... ) {
	theta <- seq(pi/4, 2*pi, length.out=8)
	xy <- xy.coords(x,y)
	xo <- r*strwidth('x')
	yo <- r*strheight('x')
	for (i in theta) {
		text( xy$x + cos(i)*xo, xy$y + sin(i)*yo, labels, col=bg, ... )
	}
	text(xy$x, xy$y, labels, col=col, ... )
}

#helper function to generate a overlay label image for gather town icon
makeOverlay <- function(posternum,res=32,textsize=5) {
	#prep output image file
	outfile <- sprintf("processed/overlay_%s.png",posternum)
	png(outfile,3*res,2*res,res=res)
	#set graphical parameters to borderless and transparent background
	op <- par(mar=c(0,0,0,0),bg=NA)
	#create new canvas and draw text in the center
	plot.new()
	shadowtext(0.5,0.6,posternum,cex=textsize)
	#restore parameters and close image device
	par(op)
	invisible(dev.off())
}

#load poster list
posterList <- read.csv("posterList.csv")
#generate tags for each author (<lastname>_<firstname>)
# nametag <- tolower(sapply(strsplit(posterList$Presenter.Name," "),function(names){
# 	lastname <- tolower(tail(names,1))
# 	# initial <- tolower(substr(names[[1]],1,1))
# 	firstname <- tolower(head(names,1))
# 	paste0(lastname,"_",firstname)
# }))
#find matching raw images for each tag
# rawfiles <- sapply(nametag,function(tag) {
# 	fs <- list.files("raw",full.names=TRUE,pattern=tag)
# 	if (length(fs)==0) {
# 		logger$warn("No image found for ",tag)
# 		return(NA)
# 	} else if (length(fs) > 1) {
# 		logger$warn("Multiple matches found for ",tag,": ",paste(fs,collapse=", "))
# 		logger$warn("Using first match only!")
# 		return(fs[[1]])
# 	} else {
# 		return(fs)
# 	}
# })

# #check that all raw images are accounted for
# leftovers <- setdiff(list.files("raw",full.names=TRUE),rawfiles)
# if (length(leftovers)>0) {
# 	logger$warn("Unmatched image(s):",paste(leftovers,collapse=", "))
# }

#find matching raw images for each presesnter
posterfiles <- list.files("Poster image (File responses)",full.names=TRUE)
posterfile.names <- yogitools::extract.groups(posterfiles,"- (.*)\\.\\w+$")
posterList$rawfile <- sapply(posterList$Presenter.Name,function(n) {
  if (n %in% posterfile.names) {
    paste(posterfiles[which(posterfile.names == n)],collapse="|")
  } else NA
})

#Unrecognized files:
leftovers <- setdiff(posterfile.names,posterList$Presenter.Name)
if (length(leftovers)>0) {
	logger$warn("Unmatched image(s):",paste(leftovers,collapse=", "))
}

#add file links to table
# posterList$rawfile <- rawfiles

#process images
invisible(yogitools::rowApply(posterList[!is.na(posterList$rawfile),],function(Poster.number,rawfile,...) {
	logger$info("Processing ",Poster.number)
	if (!file.exists(paste0("processed/",Poster.number,"_full.png"))) {
		makeOverlay(Poster.number)
		system2("bash",args=c(
			"scaleAndComposite.sh",
			Poster.number,
			paste0("'",rawfile,"'")
		),wait=TRUE)
	} else {
		# logger$info("Already processed. Skipping...")
	}
}))


logger$info("Generating index HTML document")
htmlfile <- "processed/posterList.html"

if (file.exists(htmlfile)) {
	logger$info("...already exists. skipping.")
	logger$info("Processing complete!")
	quit(save="no")
}

#generate index document for rooms
posterList$roomAssignments <- sapply(posterList$Poster.number,substr,1,1)
timeSlots <- c(
	"11:05-11:35 EST","11:35-12:05 EST","12:25-12:55 EST","12:55-13:25 EST"
)[posterList$Time.slot]
posterList$Time.slot <- timeSlots

#generate html listings for each room
htmlTables <- tapply(1:nrow(posterList),posterList$roomAssignments,function(idx) {
	room <- posterList[idx[[1]],"roomAssignments"]
	pnums <- posterList[idx,"Poster.number"]
	psubnum <- as.integer(substr(pnums,2,nchar(pnums)))
	subtable1 <- posterList[idx[psubnum <= 8],1:4]
	subtable2 <- posterList[idx[psubnum > 8],1:4]
	paste(
		sprintf("<h1 id=\"%s\">Posters %s</h1>",tolower(room),room),
		sprintf("<h2 id=\"%s1\">Posters %s1-%s8</h2>",tolower(room),room,room),
		"<table>",
		"<tr><th>Poster number</th> <th>Presentation time</th> <th>Presenter</th> <th>Poster title</th></tr>",
		df2html(subtable1),
		"</table>",
		sprintf("<h2 id=\"%s9\">Posters %s9-%s%d</h2>",tolower(room),room,room,max(psubnum)),
		"<table>",
		"<tr><th>Poster number</th> <th>Presentation time</th> <th>Presenter</th> <th>Poster title</th></tr>",
		df2html(subtable2),
		"</table>",
		sep="\n"
	)
})

#html document header
header <- "<!DOCTYPE html>
<html>
<head>
  <title>Poster Index</title>
  <style type=\"text/css\">
    html {
      font-family: sans-serif;
    }
    .main {
      margin: 1cm;
      font-size: 120%;
    }
    td {
      padding-bottom: .5ex;
    }
    th {
      text-align: left;
      background-color: #ccccdd;
    }
    table{
    	width: 100%;
    }
  </style>
</head>
<body>
	<div class=\"main\">"

#and footer
footer <- "
	</div>
</body>
</html>
"

#write HTML document ot file
cat(header,paste(htmlTables,collapse="\n"),footer,file=htmlfile)

logger$info("Processing complete!")
