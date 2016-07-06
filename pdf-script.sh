#!/bin/bash

#PDF-SCRIPT v3.2

# THIS SCRIPT WAS CREATED BY JOSHUA S. EAGLE (JOSHUASEAGLE@GMAIL.COM) 540-809-6033
# www.eagle-js.com | @eaglejs (Github)

#Global Variable(s)
filePath="/home/jeagle/Loans";

#This section of the script itterates through each folder and renames them respectfully, replaces spaces with hyphens.
function renameFiles(){
	dirlist=($(ls -d */ | sed 's/\/$//g'))
    for ((i=0; $i<=${#dirlist[*]}; i++)) do

        for file in $filePath/${dirlist[i]}/*; do mv "$file" `echo $file | sed -e 's/  */_/g' -e 's/_-_/-/g'`; done 
			
    done
}
function moveFiles(){

    shopt -s dotglob ; for dir in $filePath/*/* ; do ( cd "$dir" && mv -i ./* ../ ; ) ; done
		
}
renameFiles
moveFiles
renameFiles

#Function is used to search/store a list/and convert files to pdf.
function pdfConv(){
		 
	dirlist=($(ls -d */ | sed 's/\/$//g'))

	#if .pdf file exists, index into an array and convert each file to ps.
	dirlistMAX=${#dirlist[*]};
	for ((d=0; $d<=$dirlistMAX; d++)) do
		filelist=($(find $filePath/${dirlist[d]}/ -name *.pdf))
		comparefilelist=($(find $filePath/${dirlist[d]}/ -name *.pdf.ps))
		comparefilelistMAX=${#comparefilelist[*]};
		filelistMAX=${#filelist[*]};
		correctfilelistMAX=$(($filelistMAX-2));
		if [ $filelistMAX -ge 1 ]; then
			echo "Converting PDF files in ${dirlist[d]}."
		for ((p=0; $p<=$correctfilelistMAX; p++)) do	
			
			pdf2ps ${filelist[p]} ${filelist[p]}.ps
			rm ${filelist[p]}
			
		done		

		else 
			echo "Success!"
		fi
	  
	done
} 
#Function is used to search/store a list/and convert files to ps.      
function psConv(){
		 
    dirlist=($(ls -d */ | sed 's/\/$//g'))
        
        #if .ps file exists, index into an array and convert each file to pdf.
    dirlistMAX=${#dirlist[*]};
    for ((d=0; $d<=$dirlistMAX; d++)) do
        filelist=($(find $filePath/${dirlist[d]}/ -name *.ps))
        comparefilelist=($(find $filePath/${dirlist[d]}/ -name *.ps.pdf))
        comparefilelistMAX=${#comparefilelist[*]};
        filelistMAX=${#filelist[*]};
        correctfilelistMAX=$(($filelistMAX-2));
        if [ $filelistMAX -ge 1 ]; then
            echo "Converting PS files in ${dirlist[d]}."
        for ((p=0; $p<=$correctfilelistMAX; p++)) do	
            
            gs -dBATCH -dNOPAUSE -dNOPLATFONTS -sPAPERSIZE=letter -sDEVICE=pdfwrite -sOutputFile=${filelist[p]}.pdf ${filelist[p]}      
            
        done		

        else 
            echo "Success!"
        fi
    done	
}
pdfConv
psConv

#Function is used to search/store a list/and merges pdf files to a MASTER pdf file.
function mergeConv(){
	
    echo "\"Loan Number\" \"Number of PDF's\" \"Number of Bookmarks\"" >> pdf-log.csv
    dirlist=($(ls -d */ | sed 's/\/$//g'))
             
    mkdir $filePath/FC\ Work/
    #if .pdf file exists, index into an array and merges each file to one MASTER loan-number pdf.
    dirlistMAX=${#dirlist[*]};
    for ((d=0; $d<=$dirlistMAX; d++)) do
    pdflist=$(find $filePath/${dirlist[d]}/ -name *.pdf);
    pdflistMAX=${#pdflist[*]};
    correctdirlistMAX=$(($dirlistMAX - 1));
        
    if [ $dirlistMAX -ge 1 ]; then
        echo "Merging each folder's PDF files in ${dirlist[d]}."
        for ((p=0; $p<=$correctdirlistMAX; p++)) 
        
        do	
            # First we remove the pdfmarks file, since we'll be building it from scratch
            rm pdfmarks

            # ChapterNumber is simple the number of the chapter, one chapter per pdf
            ChapterNumber=0
            NumberOfPages=1
            
            pdflistNumber=$(($(ls $filePath/${dirlist[p]}/*.pdf -l | grep -v ^d | wc -l)));
            for f in $(ls ${dirlist[p]}/*.pdf)
        
                do
                    # We add one to the chapter number
                    ChapterNumber=$(($ChapterNumber + 1))
                    # And we print this weird line into our pdfmarks file
                    echo "[/Title ($ChapterNumber . $f) /Page $NumberOfPages /OUT pdfmark" >> pdfmarks
            
                    # We get the number of pages from a small utility called pdfinfo.
                    # We add the number of pages in the current file to the NumberOfPages counter
                    NumberOfPages=$(($NumberOfPages + $(pdfinfo $f | grep -i "Pages:" | awk '{print $2}') ))
                    # now we're finished with this file.. on to the next
                done
            
            if [ $ChapterNumber != $pdflistNumber ]; then
                echo "${dirlist[p]} is having issues with merging one of the PDF's and indexing it as a bookmark # of PDF files = $pdflistNumber, # of chapters $ChapterNumber (these two files should match)" >> pdf-error-log.txt
            fi	
            echo "${dirlist[p]} $pdflistNumber $ChapterNumber" >> pdf-log.csv
            echo "Number of bookmarks = $ChapterNumber - - - - Number of files = $pdflistNumber";
            filelistArray=($(find $filePath/${dirlist[p]}/ -name *.pdf))
            gs -dBATCH -dNOPAUSE -dNOPLATFONTS -sPAPERSIZE=letter -sDEVICE=pdfwrite -sOutputFile=$filePath/${dirlist[p]}/MASTER\ ${dirlist[p]}.pdf ${dirlist[p]}/*.pdf pdfmarks
            #pdftk ${dirlist[p]}/*.pdf output /$filePath/${dirlist[p]}/MASTER\ ${dirlist[p]}.pdf 
            mkdir $filePath/FC\ Work/${dirlist[p]} 
            cp $filePath/${dirlist[p]}/MASTER\ ${dirlist[p]}.pdf $filePath//FC\ Work/${dirlist[p]}
            chmod a+rwx $filePath/*
        done		
    else 
        #creates the log file which randomly generates a number so it will always be different.
        echo "Either there is no PDF's that exist, or something went wrong in the folder ${dirlist[p]}" >> Error-log.txt
    
    fi
    done
    chmod a+rwx $filePath/FC\ Work/*
}
#calling the last function which merges all the files to one Master document.
mergeConv
