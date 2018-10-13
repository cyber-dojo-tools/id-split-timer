
Given a 6-digit ID what is the best way to map that ID
into a dir structure to achieve fastest read/writes?
eg given id == 'ejdqsc'

```
3/3   -> 'ejd/qsc'
2/2/2 -> 'ej/dq/sc'
1/1/1/1/1/1 -> 'e/j/d/q/s/c'
```

etc

Assuming an alphabet of 0-9 (10 letters):
3/3 means fewer dirs (2)
but more entries to look through at each dir (10^3==1000)

1/1/1/1/1/1 means more dirs (6)
but less entries to look though at each dir (10^1==10)

This program gathers data to help make a decision.

