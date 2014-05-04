make prog n=1 > prog1out
make prog n=2 > prog2out
make prog n=3 > prog3out
make prog n=4 > prog4out
make prog n=5 > prog5out

if [ -e ../prog1out ]
then
	echo prog1 diff > diffout
	echo ========== >> diffout
	diff ../prog1out prog1out >> diffout
	echo >> diffout
fi

if [ -e ../prog2out ]
then
	echo prog2 diff >> diffout
	echo ========== >> diffout
	diff ../prog2out prog2out >> diffout
	echo >> diffout
fi

if [ -e ../prog3out ]
then
	echo prog3 diff >> diffout
	echo ========== >> diffout
	diff ../prog3out prog3out >> diffout
	echo >> diffout
fi

if [ -e ../prog4out ]
then
	echo prog4 diff >> diffout
	echo ========== >> diffout
	diff ../prog4out prog4out >> diffout
	echo >> diffout
fi

if [ -e ../prog5out ]
then
	echo prog5 diff >> diffout
	echo ========== >> diffout
	diff ../prog5out prog5out >> diffout
	echo >> diffout
fi

