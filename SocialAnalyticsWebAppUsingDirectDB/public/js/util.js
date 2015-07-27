// String manipulation funcions.
function trimString(str) {
	if (str && (str != null)) {
		return str.replace(/^\s+|\s+$/g, '');
	}

	return null;
}

function isStringEmpty(str) {
	var trimmed = trimString(str);

	if ((trimmed == null) || (trimmed == "")) {
		return true;
	}

	return false;
}

// DOM functions.
function clearInnerHtml(elementId) {
	var element = document.getElementById(elementId);

	if (element) {
		element.innerHTML = "";
	}
}

function hideElementById(elementId) {
	if (elementId) {
		var element = document.getElementById(elementId);

		if (element) {
			element.style.display = "none";
		}
	}
}

function showElementById(elementId) {
	if (elementId) {
		var element = document.getElementById(elementId);

		if (element) {
			element.style.display = "block";
		}
	}
}

function insertTableRow(table, tableData) {
	// Inserting the row at the end of the table.
	var row = table.insertRow(-1);
	row.className = "tr";

	for (var i in tableData) {
		var cell = row.insertCell(i);
		cell.className = "td";
		var cellData = tableData[i];

		if (typeof cellData == "object") {
			cell.appendChild(cellData);
			cell.align = "center";
		} else {
			cell.innerHTML = tableData[i];
		}
	}

	return row;
}

function clearTableElement(table) {
	if (table) {
		var rowCount = table.rows.length - 1;

		if (rowCount > 0) {
			for (var i=rowCount; i>0; i--) {
				table.deleteRow(i);
			}
		}
	}
}

function createButton(label, onclickHandler, styleClassName) {
	var button = document.createElement("button");
	button.innerHTML = label;

	if (onclickHandler != null) {
		button.onclick = onclickHandler;
	}

	if (styleClassName && (styleClassName != null)) {
		button.className = styleClassName;
	}

	return button;
}

function createLink(parameters) {
	if (parameters) {
		var link = document.createElement("a");

		for (var property in parameters) {
			if (property == "text") {
				link.innerHTML = parameters[property];
			} else {
				link.setAttribute(property, parameters[property]);
			}
		}

		return link;
	}
}

function createSpan(parameters) {
	if (parameters) {
		var span = document.createElement("span");

		for (var property in parameters) {
			if (property == "text") {
				span.innerHTML = parameters[property];
			} else {
				span.setAttribute(property, parameters[property]);
			}
		}

		return span;
	}
}

// HTTP functions.
function doHttpGet(url, responseHandler, errorHandler, httpRequestHeaders) {
	jQuery.ajax({
		type: "GET",
		url: url,
		dataType: "json",
		headers: httpRequestHeaders,
		success: responseHandler,
		error: errorHandler
	});
}

function doHttpPost(url, payload, responseHandler, errorHandler, httpRequestHeaders) {
	jQuery.ajax({
		type: "POST",
		url: url,
		data: payload,
		headers: httpRequestHeaders,
		success: responseHandler,
		error: errorHandler
	});
}

// JSON data manipulation functions.
// Converts a JSON string to a javascript object.
function fromJsonString(jsonStr) {
	if (jsonStr && (!isStringEmpty(jsonStr))) {
		return JSON.parse(jsonStr);
	}
	
	return null;
}

// Charting functions.
function drawPieChart(targetElementId, chartData) {
	var callbackHandler = function() {
		var data = google.visualization.arrayToDataTable(chartData);
		var options = {
			pieSliceText: 'none',
			slices: {
				width: 400,
  				height: 240, 
				1: {offset: 0.2},
				3: {offset: 0.3}
			}
		};
		var chart = new google.visualization.PieChart(document.getElementById(targetElementId));
        chart.draw(data, options);
	};

	google.setOnLoadCallback(callbackHandler());
}

function drawDateAxisChart(targetElementId, chartData) {
	var callbackHandler = function() {
		var data = google.visualization.arrayToDataTable(chartData);
		var options = {
			curveType: 'function',
			legend: {
				position: 'bottom', 
				width:'1200', 
				height:'500'
			}
		};
		var chart = new google.visualization.LineChart(document.getElementById(targetElementId));
        chart.draw(data, options);
	};

	google.setOnLoadCallback(callbackHandler());
}

function drawBarChart(targetElementId, chartData, chartTitle) {
	var callbackHandler = function() {
		var data = google.visualization.arrayToDataTable(chartData);
		var view = new google.visualization.DataView(data);
		var options = {
			title: chartTitle,
			legend: {
				position: 'none'
			},
			pieHole: 0.4
		};
		var chart = new google.visualization.ColumnChart(document.getElementById(targetElementId));
        chart.draw(view, options);
	};

	google.setOnLoadCallback(callbackHandler());
}