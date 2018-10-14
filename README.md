
Given a 6-digit ID, what is the best way to map that ID
into a directory structure to achieve fastest read/writes?

eg given id == 'ejdqsc'

* 3/3   -> 'ejd/qsc'
* 2/2/2 -> 'ej/dq/sc'
* 1/1/1/1/1/1 -> 'e/j/d/q/s/c'

Assuming an alphabet of 0-9 (10 letters):

* 3/3 means fewer dirs (2) but more entries to look through at each dir (10^3==1000)
* 1/1/1/1/1/1 means more dirs (6) but less entries to look though at each dir (10^1==10)

# Examples of use
## Time all possible splits of an id of given length, eg 3
```
$ ./run_id_split_timer.sh --id_size=3

all_max=2000
sample_max=3
id_size=3

           [1, 1, 1]  L0(1) S:100% M:100% L1(1) S:100% M:100% L2(1) S:100% M:100% W:100%(27) /tmp/id_splits/y/U/M
              [1, 2]  L0(1) S:100% M:100% L1(2) S:100% M:100% W:100%(9) /tmp/id_splits/i/fD
              [2, 1]  L0(2) S:100% M:100% L1(1) S:100% M:100% W:100%(9) /tmp/id_splits/9z/3
                 [3]  L0(3) S:100% M:100% W:100%(3) /tmp/id_splits/07O

    make 0.0007939 <-- [1, 1, 1]
    make 0.0008106 <-- [2, 1]
    make 0.0008795 <-- [3]
    make 0.0009741 <-- [1, 2]
 exists? 0.0000097 <-- [3]
 exists? 0.0000105 <-- [1, 1, 1]
 exists? 0.0000124 <-- [2, 1]
 exists? 0.0000149 <-- [1, 2]
    read 0.0000157 <-- [3]
    read 0.0000182 <-- [1, 1, 1]
    read 0.0000189 <-- [2, 1]
    read 0.0000252 <-- [1, 2]
   write 0.0000276 <-- [3]
   write 0.0000296 <-- [2, 1]
   write 0.0000365 <-- [1, 1, 1]
   write 0.0000448 <-- [1, 2]
     all 0.0002148 <-- [1, 1, 1]
     all 0.0002179 <-- [2, 1]
     all 0.0002331 <-- [3]
     all 0.0002648 <-- [1, 2]
```

## Time a given split, eg [2,3,1]
```
$ ./run_id_split_timer.sh --split=[2,3,1]
all_max=2000
sample_max=3
id_size=6

           [2, 3, 1]  L0(2) S:100% M:100% L1(3) S:100% M:100% L2(1) S:100% M:100% W:100%(27) /tmp/id_splits/eZ/0i4/x

    make 0.0007955 <-- [2, 3, 1]
 exists? 0.0000091 <-- [2, 3, 1]
    read 0.0000169 <-- [2, 3, 1]
   write 0.0000332 <-- [2, 3, 1]
     all 0.0002137 <-- [2, 3, 1]

```

The output shows the creation of nested dirs for each split (eg [1,1,1]).
At each level (L), the dirs have to be spliced together (S),
then the dirs have to be made (M), and lastly an example of a nested dir.
Then run timed operations to make a directory, check if a directory exists,
read a file from a directory, write a file to a directory.
Finally, show the average times for each operation, together with the average
for all operations.

# Parameters
## --split=[1,1,2,1]
Time just a single given split.

## --id_size=4
Time all possible splits of an id of the given size.
Defaults to 6.

## --all_max=1000
Generate this many sub-dirs, at each level, on the current sample.
Defaults to 2000.

## --sample_max=4
Retain this many dirs, at each level, when forming nested dirs.
Defaults to 3.

