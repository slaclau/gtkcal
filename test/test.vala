int main (string[] argv) {
    var ical_string =
        "BEGIN:VEVENT
DTSTAMP:20241130T123000Z
SEQUENCE:0
UID:uid3@example.com
ORGANIZER:mailto:jdoe@example.com
ATTENDEE;RSVP=TRUE:mailto:jsmith@example.com
DTSTART:20241130T123000Z
DTEND:20241130T210000Z
CATEGORIES:MEETING,PROJECT
CLASS:PUBLIC
SUMMARY:Calendaring Interoperability Planning Meeting
DESCRIPTION:Discuss how we can test c&s interoperability\n
using iCalendar and other IETF standards.
LOCATION:LDB Lobby
ATTACH;FMTTYPE=application/postscript:ftp://example.com/pub/
conf/bkgrnd.ps
END:VEVENT";

    var ical_event = new ICal.Component.from_string (ical_string);

    var idt_start = ical_event.get_dtstart ();
    stdout.printf ("%s\n", idt_start.as_ical_string ( ));
    var dt_start = GtkCal.icaltime_to_date_time (idt_start);
    stdout.printf ("%s\n", dt_start.format_iso8601 ( ));
    stdout.printf ("%s\n", ical_event.get_description ( ));
    return 0;
}
