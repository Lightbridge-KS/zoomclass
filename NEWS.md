# zoomclass 0.1.1

A high-level data analysis R package for Zoom's participants report `.csv` and Zoom's chat `.txt` file.

### **Zoom Participants Report**

**Read**

-   [`read_participants()`](https://lightbridge-ks.github.io/zoomclass/reference/read_participants.html): read Zoom's participant `.csv` file and clean column names.

**Process**

-   [`class_session()`](https://lightbridge-ks.github.io/zoomclass/reference/class_session.html): compute summary per sessions

-   [`class_students()`](https://lightbridge-ks.github.io/zoomclass/reference/class_students.html): compute summary per students

-   [`class_studentsID()`](https://lightbridge-ks.github.io/zoomclass/reference/class_studentsID.html): compute summary per student's ID

**Metadata**

-   [`meeting_overview()`](https://lightbridge-ks.github.io/zoomclass/reference/meeting_overview.html): Retrieve overview of meeting information

-   [`class_overview()`](https://lightbridge-ks.github.io/zoomclass/reference/class_overview.html): Retrieve overview of class room information

### **Zoom Chat**

-   [`read_zoom_chat()`](https://lightbridge-ks.github.io/zoomclass/reference/read_zoom_chat.html): Read a raw Zoom chat file from `.txt` to a tibble.

-   [`zoom_chat_extract()`](https://lightbridge-ks.github.io/zoomclass/reference/zoom_chat_extract.html): Parse Zoom chat as a character vector to a tibble.

-   [`zoom_chat_count()`](https://lightbridge-ks.github.io/zoomclass/reference/zoom_chat_count.html): Count how many times each participants replies in the Zoom chat box and also group messages entries per participants.

### Example Data

-   [`zoomclass_example()`](https://lightbridge-ks.github.io/zoomclass/reference/zoomclass_example.html): Get path to zoomclass example

-   [`heroes_students`](https://lightbridge-ks.github.io/zoomclass/reference/heroes_students.html)
