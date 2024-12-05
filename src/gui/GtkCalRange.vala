public enum GtkCal.RangeType {
    GTKCAL_RANGE_DEFAULT,
    GTKCAL_RANGE_DATE_ONLY
}

public enum GtkCal.RangeOverlap {
    GTKCAL_RANGE_NO_OVERLAP,
    GTKCAL_RANGE_INTERSECTS,
    GTKCAL_RANGE_SUBSET,
    GTKCAL_RANGE_EQUAL,
    GTKCAL_RANGE_SUPERSET,
}

public enum GtkCal.RangePosition {
    GTKCAL_RANGE_BEFORE = -1,
    GTKCAL_RANGE_MATCH  = 0,
    GTKCAL_RANGE_AFTER  = 1,
}

public class GtkCal.Range : Object {
    public DateTime start { get; construct; }
    public DateTime end { get; construct; }
    public GtkCal.RangeType range_type { get; construct; }

    public Range (DateTime start, DateTime end,
                  GtkCal.RangeType range_type) {
        Object (start: start, end: end, range_type: range_type);
    }

    delegate int CompareFuncType (DateTime a, DateTime b);

    private static CompareFuncType get_compare_func (GtkCal.Range a,
                                                     GtkCal.Range b) {
        if (a.range_type == GTKCAL_RANGE_DATE_ONLY ||
            b.range_type == GTKCAL_RANGE_DATE_ONLY) {
            return GtkCal.date_time_compare_date;
        } else {
            return (CompareFuncType) DateTime.compare;
        }
    }

    public static GtkCal.Range union (GtkCal.Range a, GtkCal.Range b) {
        DateTime start;
        DateTime end;
        GtkCal.RangeType range_type;

        CompareFuncType compare_func = get_compare_func (a, b);

        if (compare_func (a.start, b.start) < 0) {
            start = a.start;
        } else {
            start = b.start;
        }

        if (compare_func (a.end, b.end) > 0) {
            end = a.end;
        } else {
            end = b.end;
        }

        if (a.range_type == GTKCAL_RANGE_DATE_ONLY ||
            b.range_type == GTKCAL_RANGE_DATE_ONLY) {
            range_type = GTKCAL_RANGE_DATE_ONLY;
        } else {
            range_type = GTKCAL_RANGE_DEFAULT;
        }

        return new GtkCal.Range (start, end, range_type);
    }

    public bool contains_datetime (DateTime datetime) {
        switch (range_type) {
        case GTKCAL_RANGE_DEFAULT:
            return datetime.compare (start) >= 0 && datetime.compare (end) < 0;
        case GTKCAL_RANGE_DATE_ONLY:
            return GtkCal.date_time_compare_date (datetime, start) >= 0 &&
                   GtkCal.date_time_compare_date (datetime, end) < 0;
        default:
            assert_not_reached ();
        }
    }

    public static GtkCal.RangeOverlap calculate_overlap (GtkCal.Range a,
                                                         GtkCal.Range b,
                                                         out GtkCal.
                                                         RangePosition?
                                                         out_position) {
        GtkCal.RangeOverlap overlap;
        GtkCal.RangePosition position;
        var compare_func = get_compare_func (a, b);

        int start_diff = compare_func (a.start, b.start);
        int end_diff = compare_func (a.end, b.end);

        if (start_diff == 0 && end_diff == 0) {
            overlap = GtkCal.RangeOverlap.GTKCAL_RANGE_EQUAL;
            position = GtkCal.RangePosition.GTKCAL_RANGE_MATCH;
        } else {
            if (start_diff == 0) {
                if (end_diff > 0) {
                    overlap = GtkCal.RangeOverlap.GTKCAL_RANGE_SUPERSET;
                    position = GtkCal.RangePosition.GTKCAL_RANGE_AFTER;
                } else {
                    overlap = GtkCal.RangeOverlap.GTKCAL_RANGE_SUBSET;
                    position = GtkCal.RangePosition.GTKCAL_RANGE_BEFORE;
                }
            } else if (end_diff == 0) {
                int a_start_b_end_diff = compare_func (a.start, b.end);
                int a_end_b_start_diff = compare_func (a.end, b.start);

                if (a_start_b_end_diff >= 0) {
                    overlap = GtkCal.RangeOverlap.GTKCAL_RANGE_NO_OVERLAP;
                    position = GtkCal.RangePosition.GTKCAL_RANGE_AFTER;
                } else if (a_end_b_start_diff <= 0) {
                    overlap = GtkCal.RangeOverlap.GTKCAL_RANGE_NO_OVERLAP;
                    position = GtkCal.RangePosition.GTKCAL_RANGE_BEFORE;
                } else if (start_diff < 0) {
                    overlap = GtkCal.RangeOverlap.GTKCAL_RANGE_SUPERSET;
                    position = GtkCal.RangePosition.GTKCAL_RANGE_BEFORE;
                } else {
                    overlap = GtkCal.RangeOverlap.GTKCAL_RANGE_SUBSET;
                    position = GtkCal.RangePosition.GTKCAL_RANGE_AFTER;
                }
            } else {
                if (start_diff < 0 && end_diff > 0) {
                    overlap = GtkCal.RangeOverlap.GTKCAL_RANGE_SUPERSET;
                    position = GtkCal.RangePosition.GTKCAL_RANGE_BEFORE;
                } else if (start_diff > 0 && end_diff < 0) {
                    overlap = GtkCal.RangeOverlap.GTKCAL_RANGE_SUBSET;
                    position = GtkCal.RangePosition.GTKCAL_RANGE_AFTER;
                } else {
                    int a_start_b_end_diff = compare_func (a.start, b.end);
                    int a_end_b_start_diff = compare_func (a.end, b.start);

                    if (a_start_b_end_diff >= 0) {
                        overlap = GtkCal.RangeOverlap.GTKCAL_RANGE_NO_OVERLAP;
                        position = GtkCal.RangePosition.GTKCAL_RANGE_AFTER;
                    } else if (a_end_b_start_diff <= 0) {
                        overlap = GtkCal.RangeOverlap.GTKCAL_RANGE_NO_OVERLAP;
                        position = GtkCal.RangePosition.GTKCAL_RANGE_BEFORE;
                    } else {
                        if (start_diff < 0 && a_end_b_start_diff > 0 &&
                            end_diff < 0) {
                            overlap =
                                GtkCal.RangeOverlap.GTKCAL_RANGE_INTERSECTS;
                            position = GtkCal.RangePosition.GTKCAL_RANGE_BEFORE;
                        } else if (start_diff > 0 && a_start_b_end_diff < 0 &&
                                   end_diff > 0) {
                            overlap =
                                GtkCal.RangeOverlap.GTKCAL_RANGE_INTERSECTS;
                            position = GtkCal.RangePosition.GTKCAL_RANGE_AFTER;
                        } else {
                            assert_not_reached ();
                        }
                    }
                }
            }
        }
        out_position = position;
        return overlap;
    }

    public string to_string () {
        return "[%s | %s)".printf (start.format_iso8601 (      ),
                                   end.format_iso8601 (      ));
    }

    public string to_date_string () {
        return "[%s | %s)".printf (start.format ("yyyy-MM-dd"),
                                   end.format ("yyyy-MM-dd"));
    }
}
