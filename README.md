# Microfluidics - Post-processing
Matlab programs used to post-process data coming from the microfluidics project.

Two possibilites:
- if the file is "easy to clean", then use `imagProc.m`, with a RGB or B&W `.avi` video;
- if the file is not, use `imageProcLight.m`, with two B&W already cleaned videos (the droplet should be **black**, and the background **white**).

Reminder for ImageJ (frequent operations):
* *Image > Color > Split channels*
* *Image > Duplicate > Duplicate Stack*
* *Image > Stacks > Z Project > Projection Type: Median*
* *Image > Adjust > Threshold*
* *Process > Image Calculator > Difference*
* *Process > Binary > Make binary*
* *Process > Binary > Erode*
* *Process > Binary > Dilate*
* *Process > Binary > Fill Holes*
* *Analyze > Analyze Particles > Show: Bare Outlines*
* *File > Save As > AVI*

Comments:
- warning: the script takes quite a lot of time and space;
- *LComp* only makes sense if each droplet is saved at least once, which is not necessarily true (in particular if the window rectangle is too small or if the acquisition frequency is too small).