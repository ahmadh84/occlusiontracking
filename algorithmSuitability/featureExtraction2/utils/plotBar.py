from pylab import *
val = 3+10*rand(5)    # the bar lengths
pos = arange(5)+.5    # the bar centers on the y axis
p = [10,200,30,40,50]

figure(2)
barh(pos,p)
yticks(pos, ('BA', 'TV', 'HS', 'FL', 'Ours'))
xlabel('Total Epe')
grid(True)

show()
