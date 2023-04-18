# Index Rebuild Threshold After DML

## Question
If I recall correctly there was a threshold in place that indexes would be rebuild on DML once DML changed more than x-% of data in a table - is that still correct with V.6.2.8 ? Stumbled upon a scenario where someone inserted a few billion records and I'd have thought that the INSERT part would finish and then there would be INDEX REBUILD steps but instead it took place as INDEX INSERT...or did the REBUILD-part only apply to UPDATEs?

## Answer
Automatic index rebuilds occur upon DELETE (over 25% rows marked as deleted triggers the rebuild, you can see DELETE_PERCENTAGE in exa_dba_tables) and upon UPDATE (over 15% rows affected by an update triggers the rebuild).

INSERT doesn't trigger index rebuild. 