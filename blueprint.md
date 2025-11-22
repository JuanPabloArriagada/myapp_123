# Project Overview

This is a Flutter application that allows users to report incidents. The app consists of three main screens:

1.  **List of Reports:** Displays a list of all submitted reports.
2.  **Report Details:** Shows the details of a specific report.
3.  **New Report:** A form to create and submit a new report, including a description, a photo, and the user's location.

# Features

*   **View Reports:** Users can see a list of all reports with a brief description and an image.
*   **View Report Details:** Users can tap on a report to see more details, including the full description and location.
*   **Create Report:** Users can create a new report by providing their email, a description of the incident, a photo taken with the camera, and their current location.

# Current Task: Fix Errors

The following changes were made to fix the errors in the project:

*   **`pubspec.yaml`:**
    *   Resolved dependency conflicts by removing duplicate entries and organizing the dependencies.
    *   Updated the `http`, `image_picker`, `geolocator`, and `permission_handler` packages to their latest compatible versions.
*   **`lib/main.dart`:**
    *   Fixed an issue where `BuildContext` was used across asynchronous gaps in the `_enviar` method. The code was refactored to ensure that all operations dependent on `BuildContext` are performed only when the widget is still mounted. This prevents potential crashes and ensures that the UI is updated correctly after asynchronous operations.