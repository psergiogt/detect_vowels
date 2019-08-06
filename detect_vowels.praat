clearinfo
form Counting vowels in Sound Utterances
	choice type: 1
		button Record
		button Use file
	sentence directory C:\Users\Desktop
	sentence fileName Recording
	choice fileExtension: 1
		button WAV
		button AIFF
		button AIFC
		button FLAC
		button NIST
		button MP3
	sentence recordTime 5
	choice gender: 1
		button Male
		button Female
endform
if type=1
	printline Please speak for 'recordTime$' seconds
	Record Sound (fixed time)... Microphone 0.99 0.5 44100 'recordTime$'
	clearinfo
	if fileExtension = 1
		Write to WAV file... 'directory$'/'fileName$'.wav
	elsif fileExtension=2
		Write to AIFF file... 'directory$'/'fileName$'.aiff
	elsif fileExtension=3
		Write to AIFC file... 'directory$'/'fileName$'.aifc
	elsif fileExtension=4
		Write to FLAC file... 'directory$'/'fileName$'.flac
	elsif fileExtension=5
		Write to NIST file... 'directory$'/'fileName$'.nist
	else
		printline MP3 not supported, saving as WAV
		Write to WAV file... 'directory$'/'fileName$'.wav
	endif
else
	Read from file... 'directory$'/'fileName$'.'fileExtension$'
endif

if gender = 1
	value=5000
	beginPause: "Select formant ranges"
		real: "mini1", 219
		real: "maxi1", 310
		real: "mini2", 2159
		real: "maxi2", 2477
		real: "minu1", 249
		real: "maxu1", 329
		real: "minu2", 611
		real: "maxu2", 727
		real: "mino1", 412
		real: "maxo1", 537
		real: "mino2", 719
		real: "maxo2", 1070
		real: "mine1", 386
		real: "maxe1", 520
		real: "mine2", 1846
		real: "maxe2", 2142
		real: "mina1", 617
		real: "maxa1", 698
		real: "mina2", 1111
		real: "maxa2", 1320
	endPause: "Continue", 1
else
	value=5500
	beginPause: "Select formant ranges"
		real: "mini1", 210
		real: "maxi1", 270
		real: "mini2", 2586
		real: "maxi2", 3083
		real: "minu1", 206
		real: "maxu1", 280
		real: "minu2", 546
		real: "maxu2", 711
		real: "mino1", 440
		real: "maxo1", 581
		real: "mino2", 832
		real: "maxo2", 1130
		real: "mine1", 445
		real: "maxe1", 538
		real: "mine2", 2085
		real: "maxe2", 2421
		real: "mina1", 598
		real: "maxa1", 729
		real: "mina2", 1054
		real: "maxa2", 1282
	endPause: "Continue", 1
endif

s$ = selected$("Sound")
s = selected("Sound")
execute workpre.praat
wrk = selected("Sound")
To TextGrid... "vowels" vowels
textgridid = selected("TextGrid")
select wrk
sr = Get sample rate
include minmaxf0.praat

pitch = To Pitch... 0.01 minF0 maxF0
	
threshold = 21
	
select wrk
	
if sr > 11025
	downsampled = Resample... 11025 1	
else		
	downsampled = Copy... tmp
endif
Filter with one formant (in-line)...  1000 500
framelength = 0.01
int_tmp = To Intensity... 40 'framelength' 0
maxint = Get maximum... 0 0 Cubic
t1 = Get time from frame... 1
matrix_tmp = Down to Matrix
endtime = Get highest x
ncol = Get number of columns
coldist = Get column distance
h=1
newt1 = 't1'+('h'*'framelength')
ncol = 'ncol'-(2*'h')
matrix_intdot = Create Matrix... intdot 0 'endtime' 'ncol' 'coldist' 'newt1' 1 1 1 1 1 (Object_'matrix_tmp'[1,col+'h'+'h']-Object_'matrix_tmp'[1,col]) / (2*'h'*dx)
temp_IntDot = To Sound (slice)... 1
temp_rises = To PointProcess (extrema)... Left yes no Sinc70
select temp_IntDot
temp_peaks = To PointProcess (zeroes)... Left no yes
npeaks = Get number of points
select downsampled
plus matrix_tmp
plus matrix_intdot
plus temp_IntDot
Remove

	
cnt = 1
	

for pindex from 1 to 'npeaks'		
	select temp_peaks		
	ptime = Get time from index... 'pindex'		
	select int_tmp		
	pint = Get value at time... 'ptime' Nearest
		
	select pitch		
	voiced = Get value at time... 'ptime' Hertz Nearest		
	if pint > (maxint-threshold) and voiced <> undefined			
		select temp_rises			
		rindex = Get low index... 'ptime'			
		if rindex >= 1				
			rtime = Get time from index... 'rindex'				
			otime = ('rtime'+'ptime')/2				
			otime_'cnt' = otime				
			otime2 = otime + 0.05				
			otime2_'cnt' = otime2				
			cnt += 1			
		endif		
	endif	
endfor

select int_tmp	
plus temp_rises	
plus temp_peaks	
plus pitch	
Remove

cnt=cnt-1
printline 'cnt' vowels were found
	
for ifile from 1 to cnt
		
	otime = otime_'ifile'		
	otime2 = otime2_'ifile'
    vowel = ((otime+otime2)/2)
	select wrk
		
	ids'ifile' = Extract part... 'otime' 'otime2' Rectangular 1 yes
    select ids'ifile'

    pitchid1 = noprogress To Pitch... 0 75 600
    vowelf0 = Get value at time... 'vowel' Hertz Linear
	#barkFreq = 13*arctan(0.00076*vowelf0) + 3.5*(arctan((vowelf0/7500)^2))
	barkFreq = vowelf0

	select ids'ifile'
    formantid = noprogress To Formant (burg)... 0 6 'value' 0.025 50
    #this sets the formant Units
    formantUnit$ = "Hertz"
    #get f1, f2, f3 values
	vowelf1 = Get value at time... 1 'vowel' 'formantUnit$' Linear
	vowelf2 = Get value at time... 2 'vowel' 'formantUnit$' Linear
	vowelf3 = Get value at time... 3 'vowel' 'formantUnit$' Linear

	#printline 'ifile'. vowel: f0 'barkFreq:2' f1 'vowelf1:2' f2 'vowelf2:2' f3 'vowelf3:2' Timestamp: 'vowel:4'
	#select textgridid
	#Insert point... 1 otime 'ifile'
	#Insert point... 1 otime2
	
	if (vowelf1>mini1 && vowelf1<maxi1 && vowelf2>mini2 && vowelf2<maxi2)
		case=1
	elsif (vowelf1>minu1 && vowelf1<maxu1 && vowelf2>minu2 && vowelf2<maxu2)
		case=2
	elsif (vowelf1>mino1 && vowelf1<maxo1 && vowelf2>mino2 && vowelf2<maxo2)
		case=3
	elsif (vowelf1>mine1 && vowelf1<maxe1 && vowelf2>mine2 && vowelf2<maxe2)
		case=4
	elsif (vowelf1>mina1 && vowelf1<maxa1 && vowelf2>mina2 && vowelf2<maxa2)
		case=5
	else
		case=6
		disti1=abs(min(('vowelf1'-'mini1'),('vowelf1'-'maxi1')))
		distu1=abs(min(('vowelf1'-'minu1'),('vowelf1'-'maxu1')))
		disto1=abs(min(('vowelf1'-'mino1'),('vowelf1'-'maxo1')))
		diste1=abs(min(('vowelf1'-'mine1'),('vowelf1'-'maxe1')))
		dista1=abs(min(('vowelf1'-'mina1'),('vowelf1'-'maxa1')))
		disti2=abs(min(('vowelf2'-'mini2'),('vowelf2'-'maxi2')))
		distu2=abs(min(('vowelf2'-'minu2'),('vowelf2'-'maxu2')))
		disto2=abs(min(('vowelf2'-'mino2'),('vowelf2'-'maxo2')))
		diste2=abs(min(('vowelf2'-'mine2'),('vowelf2'-'maxe2')))
		dista2=abs(min(('vowelf2'-'mina2'),('vowelf2'-'maxa2')))
		maxdis1=max(disti1,distu1,disto1,diste1,dista1)
		maxdis2=max(disti2,distu2,disto2,diste2,dista2)
		pctgi1=(1-('disti1'/'maxdis1'))/2
		pctgu1=(1-('distu1'/'maxdis1'))/2
		pctgo1=(1-('disto1'/'maxdis1'))/2
		pctge1=(1-('diste1'/'maxdis1'))/2
		pctga1=(1-('dista1'/'maxdis1'))/2
		pctgi2=(1-('disti2'/'maxdis2'))/2
		pctgu2=(1-('distu2'/'maxdis2'))/2
		pctgo2=(1-('disto2'/'maxdis2'))/2
		pctge2=(1-('diste2'/'maxdis2'))/2
		pctga2=(1-('dista2'/'maxdis2'))/2
		if (vowelf1>mini1 && vowelf1<maxi1 && vowelf2<mini2 && vowelf2>maxi2)
			pctgi1=0.5
		elsif (vowelf1<mini1 && vowelf1>maxi1 && vowelf2>mini2 && vowelf2<maxi2)
			pctgi2=0.5
		elsif (vowelf1>minu1 && vowelf1<maxu1 && vowelf2<minu2 && vowelf2>maxu2)
			pctgu1=0.5
		elsif (vowelf1<minu1 && vowelf1>maxu1 && vowelf2>minu2 && vowelf2<maxu2)
			pctgu2=0.5
		elsif (vowelf1>mino1 && vowelf1<maxo1 && vowelf2<mino2 && vowelf2>maxo2)
			pctgo1=0.5
		elsif (vowelf1<mino1 && vowelf1>maxo1 && vowelf2>mino2 && vowelf2<maxo2)
			pctgo2=0.5
		elsif (vowelf1>mine1 && vowelf1<maxe1 && vowelf2<mine2 && vowelf2>maxe2)
			pctge1=0.5
		elsif (vowelf1<mine1 && vowelf1>maxe1 && vowelf2>mine2 && vowelf2<maxe2)
			pctge2=0.5
		elsif (vowelf1>mina1 && vowelf1<maxa1 && vowelf2<mina2 && vowelf2>maxa2)
			pctga1=0.5
		elsif (vowelf1<mina1 && vowelf1>maxa1 && vowelf2>mina2 && vowelf2<maxa2)
			pctga2=0.5
		endif
		pctgi=('pctgi1'+'pctgi2')*100
		pctgu=('pctgu1'+'pctgu2')*100
		pctgo=('pctgo1'+'pctgo2')*100
		pctge=('pctge1'+'pctge2')*100
		pctga=('pctga1'+'pctga2')*100
		pctg=max(pctgi,pctgu,pctgo,pctge,pctga)
		if pctg=pctgi
			detected=1
		elsif pctg=pctgu
			detected=2
		elsif pctg=pctgo
			detected=3
		elsif pctg=pctge
			detected=4
		elsif pctg=pctga
			detected=5
		endif
	endif

	if case=1
		printline 'ifile'. vowel: f0 'barkFreq:2' f1 'vowelf1:2' f2 'vowelf2:2' f3 'vowelf3:2' Timestamp: 'vowel:4' Vowel: i(100%)
		select 'textgridid'
		Insert point... 1 vowel i
	elsif case=2
		printline 'ifile'. vowel: f0 'barkFreq:2' f1 'vowelf1:2' f2 'vowelf2:2' f3 'vowelf3:2' Timestamp: 'vowel:4' Vowel: u(100%)
		select 'textgridid'
		Insert point... 1 vowel u
	elsif case=3
		printline 'ifile'. vowel: f0 'barkFreq:2' f1 'vowelf1:2' f2 'vowelf2:2' f3 'vowelf3:2' Timestamp: 'vowel:4' Vowel: o(100%)
		select 'textgridid'
		Insert point... 1 vowel o
	elsif case=4
		printline 'ifile'. vowel: f0 'barkFreq:2' f1 'vowelf1:2' f2 'vowelf2:2' f3 'vowelf3:2' Timestamp: 'vowel:4' Vowel: e(100%)
		select 'textgridid'
		Insert point... 1 vowel e
	elsif case=5
		printline 'ifile'. vowel: f0 'barkFreq:2' f1 'vowelf1:2' f2 'vowelf2:2' f3 'vowelf3:2' Timestamp: 'vowel:4' Vowel: a(100%)
		select 'textgridid'
		Insert point... 1 vowel a
	elsif case=6
		printline 'ifile'. vowel: f0 'barkFreq:2' f1 'vowelf1:2' f2 'vowelf2:2' f3 'vowelf3:2' Timestamp: 'vowel:4' Vowel: a('pctga:1'%) e('pctge:1'%) i('pctgi:1'%) o('pctgo:1'%) u('pctgu:1'%)
		select 'textgridid'
		if detected=1
			Insert point... 1 vowel i
		elsif detected=2
			Insert point... 1 vowel u
		elsif detected=3
			Insert point... 1 vowel o
		elsif detected=4
			Insert point... 1 vowel e
		elsif detected=5
			Insert point... 1 vowel a
		endif
	endif

	select ids'ifile'
    plus 'pitchid1'
	plus 'formantid'
    Remove
endfor

select wrk
plus textgridid
Edit

Write to text file... 'directory$'/'fileName$'.vowels.TextGrid
appendFile: "'fileName$'.txt", info$ ( )
