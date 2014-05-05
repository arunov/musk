make prog n=1 > prog1out
make prog n=2 > prog2out
make prog n=3 > prog3out
make prog n=4 > prog4out
make prog n=5 > prog5out

if [ ! -e newout ]
then
	mkdir newout
else
	if [ -e oldout ]
	then
		rm -rf oldout
	fi
	mv newout oldout
	mkdir newout
fi

mv prog*out newout

if [ -e oldout/prog1out ]
then
	echo prog1 diff > diffout
	echo ========== >> diffout
	diff oldout/prog1out newout/prog1out >> diffout
	echo >> diffout
fi

if [ -e oldout/prog2out ]
then
	echo prog2 diff >> diffout
	echo ========== >> diffout
	diff oldout/prog2out newout/prog2out >> diffout
	echo >> diffout
fi

if [ -e oldout/prog3out ]
then
	echo prog3 diff >> diffout
	echo ========== >> diffout
	diff oldout/prog3out newout/prog3out >> diffout
	echo >> diffout
fi

if [ -e oldout/prog4out ]
then
	echo prog4 diff >> diffout
	echo ========== >> diffout
	diff oldout/prog4out newout/prog4out >> diffout
	echo >> diffout
fi

if [ -e oldout/prog5out ]
then
	echo prog5 diff >> diffout
	echo ========== >> diffout
	diff oldout/prog5out newout/prog5out >> diffout
	echo >> diffout
fi

