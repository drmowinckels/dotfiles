# Custom Functions

# Mount and listen after file changes on LCBC lagringshotell
# This will occupy the terminal, and must remain so to work
function lmount {
	# check if mounted, mount if not
	if df | grep LCBC ; then  echo "already mounted"; else lcbc ; fi

	# start listener.
	echo "Running listener on file permissions in ${HOME}/lcbc/"
	echo "Keep this terminal running until you stop working on the lagringshotell"
	fswatch -0 -r ${HOME}/lcbc/ | xargs -0 -n 1 -I {} chmod 770 {} 
}

# Unmount LCBC lagringshotell convenience
function unmount { 
   kill -9 $(ps ax | grep sshfs | grep $1 | cut -d " " -f1)
   cd 
   umount -f $1
} 

# Split PDF into separate pages
function split_pdf {
	gs -sDEVICE=pdfwrite -dSAFER -o ${1%.*}_%03d.pdf $1
}

# Merge PDF files
function merge_pdf {
	gs -dNOPAUSE -sDEVICE=pdfwrite -sOUTPUTFILE=${1}.pdf -dBATCH ${1}*pdf
	mkdir -p split
	mv ${1}_*pdf split/
}
