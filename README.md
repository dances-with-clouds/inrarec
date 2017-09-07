# inrarec
inrarec - internet radio recorder - A wrapper for streamripper.

inrarec - internet radio recorder

A small wrapper for streamripper.

This script uses streamripper to record internet streams transmitted by
internet radio stations, and then it uses sox to split those streams 
into separate songs and to add a little fading. It can also burn the 
songs to a CDRW or copy them onto a USB drive.

It can also be started by udev to burn or copy a previously made 
recording without further interacting: just plug in a USB drive 
or insert a CDRW, and the process starts.

Wait a minute... this sounds like something that streamripper and 
fadecut can do!

That is correct. So why did I do it?

Streamripper and fadecut are great programms, no question about it! 

But soon after I started to use them, I realized they did not quite 
fit my personal needs. So I started to write a small script that would
do the every day work for me, and it started with just 5 lines of code 
for cron, that would download a few hours of songs from a radio station 
and burn them onto a CD, so I could enjoy the music the next day while
driving my truck, without getting bored and annoyed by being forced
to listen to the "heavy rotation" loop that most FM radio station 
transmit these days and that simply drive my mad. I hate hearing the
same set of songs in the order three times a day!

While enhancing my script, it grew on me, and I started to include more 
and more features, and this is the result. 

And most probably, this will not be the final result yet. :)

But beware: 

As I said, I wrote this script to fit my needs. Use it at your own risk!

Don't hold me responsible when it makes your PC go haywire, your milk
turns sour after starting it, or your cat brings in some nasty stuff 
from the garden!

Nonetheless, I hope that others may find it useful as well. I've used it 
for quite some time now, and it works pretty flawlessly - at least at my
machine!

If you do find any bug or if you have suggestions for making it better,
don't hesitate to contact me.

inrarec is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

inrarec is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details:
<http://www.gnu.org/licenses/>.

