// When clicking a legend item, show only that series. When clicking a
// second time, show all series again.
function(event) {
    var chart = this.chart;
    var clickedSeries = this;

    // Check if the clicked series is the only visible one
    var allVisible = chart.series.every(function(s) { return s.visible; });
    var clickedVisible = clickedSeries.visible;

    if (clickedVisible && !allVisible) {
        // Show all series if clicked again when others are hidden
        chart.series.forEach(function(s) {
            s.setVisible(true, false);
        });
    } else {
        // Otherwise, hide all other series and show only the clicked one
        chart.series.forEach(function(s) {
            s.setVisible(s === clickedSeries, false);
        });
    }

    chart.redraw();
    return false;
}
