// Defining constants.
var TWEET_SEARCH_URL = "/search-tweets?searchKey=";
var TWEET_PAGINATION_URL = "/get-tweets?page=";
var SEND_EMAIL_URL = "/send-email";
var SEND_SMS_URL = "/send-sms";
var GET_CUSTOMER_INFO_URL = "/get-customer-info?twitterId=";
var GET_MATCHING_OFFERS_URL = "/get-matching-offers";
var ADD_CUSTOMER_URL = "/add-customer";
var SYSTEM_U_URL = "https://system-u-demo-03.mybluemix.net/analyze?handle=";

// Defining global variables.
var sentimentChartData = null;
var omsChartData = null;
var sentimentTrendData = null;

var trendChartProperties = [
	{label:"Good", color:"green"},
	{label:"Bad", color:"red"},
	{label:"Indifferent", color:"blue"}
];

var currentPage = 0;
var tweetStore = null;

// Converts a JSON string to a javascript object.
function fromJsonString(jsonStr) {
	if (jsonStr && (!isStringEmpty(jsonStr))) {
		return JSON.parse(jsonStr);
	}
	
	return null;
}

function hideOffers() {
	hideElementById("offersOverlay");
	hideElementById("overlayBackground");
}

function hideInfluenceChart() {
	hideElementById("influenceChartOverlay");
	hideElementById("overlayBackground");
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

function doCrossDomainHttpPost(url, payload, responseHandler, errorHandler, httpRequestHeaders) {
	jQuery.ajax({
		type: "POST",
		crossdomain: true,
		url: url,
		data: payload,
		headers: httpRequestHeaders,
		success: responseHandler,
		error: errorHandler,
		complete: function(xhr, textStatus) {
			console.log("doCrossDomainHttpPost() completion status: " + xhr.status);
		} 
	});
}

// Charting functions.
function drawPieChart(targetElementId, chartData, showLegend) {
	// Clear already displayed chart.
	clearInnerHtml(targetElementId);

	jQuery.jqplot(targetElementId, [chartData], {
		seriesDefaults: {
			renderer: jQuery.jqplot.PieRenderer,
			rendererOptions: {
				showDataLabels: true,
				dataLabels: 'value' // Use value instead of percentage.
			}
		}, 
		legend: {show:showLegend, location: 'e'}
	});
}

function drawDateAxisChart(targetElementId, chartData, showLegend, chartProperties) {
	// Clear already displayed chart.
	clearInnerHtml(targetElementId);

	jQuery.jqplot(targetElementId, chartData, {
		axes: {
			xaxis: {
				renderer:jQuery.jqplot.DateAxisRenderer,
				tickOptions: { formatString: '%#d' },
				tickInterval: '1 day'
			}
		},
		legend: {show:showLegend, location: 'e'},
		series: chartProperties
	});
}

function drawBarChart(targetElementId, chartData, chartLabels) {
	// Clear already displayed chart.
	clearInnerHtml(targetElementId);

	return jQuery.jqplot(targetElementId, chartData, {
		seriesDefaults: {
			renderer: jQuery.jqplot.BarRenderer,
			pointLabels: {show: true}
		},
		axes: {
			xaxis: {
				renderer: jQuery.jqplot.CategoryAxisRenderer,
					ticks: chartLabels
			}
		}
	});
}

function showInfluenceBarChart(chartData) {
	var chartLabels = ['Followers Count', 'Friends Count', 'Retweet Count'];
	var chart = drawBarChart("influenceChart", chartData, chartLabels);

	showElementById("overlayBackground");
	showElementById("influenceChartOverlay");

	// Replot the chart to solve the <div> display problem.
	chart.replot();
}

// App events.
// Data handlers.
var searchResponseHandler = function(data, status) {
	if (data) {
		var sentimentData = data.sentimentChartData;

		if (sentimentData) {
			sentimentChartData = [
				['Good', sentimentData.good], 
				['Bad', sentimentData.bad], 
				['Indifferent', sentimentData.indifferent]
			];
		} else {
			sentimentChartData = null;
		}

		var omsData = data.omsChartData;

		if (omsData) {
			omsChartData = [
				["Marketing", omsData.marketing], 
				["Operations", omsData.operations], 
				["Sales", omsData.sales]
			];
		} else {
			omsChartData = null;
		}

		var trendData = data.sentimentTrendData;

		if (trendData) {
			sentimentTrendData = [];
			var goodSentiments = trendData.good;
			var badSentiments = trendData.bad;
			var indifferentSentiments = trendData.indifferent;

			if (goodSentiments) {
				var goodSentimentData = [];

				for (var key in goodSentiments) {
					goodSentimentData.push([key, goodSentiments[key]]);
				}

				sentimentTrendData.push(goodSentimentData);
			}

			if (badSentiments) {
				var badSentimentData = [];

				for (var key in badSentiments) {
					badSentimentData.push([key, badSentiments[key]]);
				}

				sentimentTrendData.push(badSentimentData);
			}

			if (indifferentSentiments) {
				var indifferentSentimentData = [];

				for (var key in indifferentSentiments) {
					indifferentSentimentData.push([key, indifferentSentiments[key]]);
				}

				sentimentTrendData.push(indifferentSentimentData);
			}
		} else {
			sentimentTrendData = null;
		}

		var tweets = populateTweetTable(data.docs);

		if (tweets != null) {
			// By default, setting page index to 1.
			currentPage = 1;

			// Storing page data in Tweet store for future use.
			tweetStore[currentPage] = tweets;
		}

		hideElementById("progressIndicator");
		showElementById("searchResult");

		showSentimentChart();
	} else {
		hideElementById("progressIndicator");
		showElementById("noDataMessage");
	}
};

var searchErrorHandler = function(request, status, error) {
	hideElementById("progressIndicator");
	showElementById("noDataMessage");
};

var nextPageDataHandler = function(data, status) {
	if (data) {
		var tweets = populateTweetTable(data.docs);

		if (tweets != null) {
			// Update current page index.
			currentPage = currentPage + 1;

			// Storing page data in Tweet store for future use.
			tweetStore[currentPage] = tweets;
		}
	}
};

function handleSearchKeyboardEvent(keyCode) {
	if (keyCode == 13) {
		search();
	}
}

function search() {
	var searchKey = document.getElementById("searchKey").value;

	if (!isStringEmpty(searchKey)) {
		currentPage = 0; // Reset current page index.
		tweetStore = {}; // Reset Tweet store.
		hideElementById("noDataMessage");
		hideElementById("searchResult");
		hideElementById("banner");
		showElementById("progressIndicator");

		try {
			// Encode the search key before appending to URL.
			searchKey = encodeURIComponent(searchKey);
			var url = TWEET_SEARCH_URL + searchKey;

			doHttpGet(url, searchResponseHandler, searchErrorHandler);
		} catch (e) {
			alert("Error in search(): " + e);
		}
	}
}

function createSystemULink(parameters) {
	if (parameters) {
		var link = document.getElementById("systemULink");
		link.innerHTML = "See detailed Personality Analytics of @" + parameters + " >>";
		link.setAttribute("href", SYSTEM_U_URL + parameters);
		link.setAttribute("class", "web-link");
		link.setAttribute("target", "_newtab");
	}
}

var customerInfoButtonResponseHandler = function(data, status) {
	if (data) {
		var rows = data.rows;

		if (rows) {
			var row = rows.row;

			if (row) {
				var message = "Customer Details: \n\n";

				for (var key in row) {
					value = row[key];
					message = message + (key + ": " + value + "\n");
				}

				alert(message);
				return;
			}
		}
	}

	alert("Customer does not exist.");
}

var customerInfoButtonHandler = function() {
	var twitterId = window.prompt("Enter Twitter Id:", this.twitterId);

	if (!isStringEmpty(twitterId)) {
		twitterId = twitterId.toLowerCase();
		var url = GET_CUSTOMER_INFO_URL + twitterId;
		doHttpGet(url, customerInfoButtonResponseHandler);
	}
}

var emailResponseHandler = function(data, status) {
	if (data) {
		alert(data);
	} else {
		alert("Email request sent successfully.");
	}
};

var emailErrorHandler = function(request, status, error) {
	console.log("Error while sending Email: " + error);
	alert("Temporarily unable to access the Email service due to network problem. Please try again later.");
};

var sendEmailButtonHandler = function() {
	var emailIdList = window.prompt("Enter semicolon(;) separated email addresses:");

	if (!isStringEmpty(emailIdList)) {
		var tweetObject = this.tweetObject;

		if (tweetObject) {
			var tweetDate = tweetObject["tweetDate"];
			var twitterId = tweetObject["twitterId"];
			var userName = tweetObject["userName"];
			var tweetType = tweetObject["tweetType"];
			var tweetMessage = tweetObject["tweetMessage"];

			var emailMsg = "<b>Date:</b> " + tweetDate 
				+ "<br><b>Twitter Id:</b> " + twitterId 
				+ "<br><b>User Name:</b> " + userName 
				+ "<br><b>Tweet Type:</b> " + tweetType 
				+ "<br><b>Tweet Message:</b> " + tweetMessage;

			var emailObject = {};
			emailObject["emailIdList"] = emailIdList;
			emailObject["emailMsg"] = emailMsg;

			var emailJsonSting = JSON.stringify(emailObject);
			var emailRequestPayload = {"data": emailJsonSting};

			// Send email request.
			doHttpPost(SEND_EMAIL_URL, emailRequestPayload, emailResponseHandler, emailErrorHandler);
		}
	}
}

var smsResponseHandler = function(data, status) {
	if (data) {
		alert(data);
	} else {
		alert("SMS request sent successfully.");
	}
};

var smsErrorHandler = function(request, status, error) {
	console.log("Error while sending SMS: " + error);
	alert("Temporarily unable to access the SMS service due to network problem. Please try again later.");
};

var sendSmsButtonHandler = function() {
	var phoneNumber = window.prompt("Enter phone number:");

	if (!isStringEmpty(phoneNumber)) {
		var tweetObject = this.tweetObject;

		if (tweetObject) {
			var tweetDate = tweetObject["tweetDate"];
			var twitterId = tweetObject["twitterId"];
			var userName = tweetObject["userName"];
			var tweetType = tweetObject["tweetType"];
			var tweetMessage = tweetObject["tweetMessage"];

			var smsMsg = "Date: " + tweetDate 
				+ "\nTwitter Id: " + twitterId 
				+ "\nUser Name: " + userName 
				+ "\nTweet Type: " + tweetType 
				+ "\nTweet Message: " + tweetMessage;

			var smsObject = {};
			smsObject["phoneNumber"] = phoneNumber;
			smsObject["smsMsg"] = smsMsg;

			var smsJsonSting = JSON.stringify(smsObject);
			var smsRequestPayload = {"data": smsJsonSting};

			// Send SMS request.
			doHttpPost(SEND_SMS_URL, smsRequestPayload, smsResponseHandler, smsErrorHandler);
		}
	}
}

var offersErrorResponseHandler = function(request, status, error) {
	console.log("Error while retrieving offers: " + error);
	alert("No offers available !");
};

var offersResponseHandler = function(data, status) {
	if (data) {
		var responseJson = data;

		if (responseJson != null) {
			// Display the offers.
			var offers = responseJson.offers;

			if (offers && (offers.length > 0)) {
				var table = document.getElementById("offersTable");

				// Remove all rows before inserting.
				clearTableElement(table);

				for (var i=0; i<offers.length; i++) {
					var tableData = [(i+1), offers[i]];
					insertTableRow(table, tableData);
				}

				showElementById("overlayBackground");
				showElementById("offersOverlay");
				return;
			}
		}

		alert("No offers available !");
	}
}

var offersButtonHandler = function() {
	var tweetObject = this.tweetObject;
	var twitterId = tweetObject["twitterId"];
	var tweetMessage = tweetObject["tweetMessage"];
	var userLocation = tweetObject["userLocation"];

	// Get customer info. to check whether the Tweet user is a customer.
	var url = GET_CUSTOMER_INFO_URL + twitterId;

	doHttpGet(url, function(data, status) {
		var isCustomer = false;

		// If customer data is available, mark the user as a customer.
		if (data) {
			var rows = data.rows;

			if (rows) {
				var row = rows.row;

				if (row) {
					isCustomer = true;
				}
			}
		}

		// Get offers relevant to the Tweet user.
		var payloadObject = {"tweet": tweetMessage, "location": userLocation, "iscustomer": isCustomer};
		var payloadString = JSON.stringify(payloadObject);
		var payload = {"data": payloadString};

		doHttpPost(GET_MATCHING_OFFERS_URL, payload, offersResponseHandler, offersErrorResponseHandler);
	});
}

function populateTweetTable(tweetData) {
	if (tweetData) {
		var tweets = [];
		var tweetTable = document.getElementById("tweetTable");

		// Remove all rows before inserting.
		clearTableElement(tweetTable);

		for (i=0; i<tweetData.length; i++) {
			var tweet = tweetData[i];

			var tweetDate = tweet.created_date;
			var twitterId = tweet.user.screen_name;
			var userName = tweet.user.name;
			var userLocation = tweet.user.location;
			var followersCount = tweet.user.followers_count;
			var friendsCount = tweet.user.friends_count;
			var retweetCount = tweet.retweet_count;
			var tweetType = tweet.tally;
			var tweetMessage = tweet.text;

			var tweetObject = {};
			tweetObject["tweetDate"] = tweetDate;
			tweetObject["twitterId"] = twitterId;
			tweetObject["userName"] = userName;
			tweetObject["userLocation"] = userLocation;
			tweetObject["followersCount"] = followersCount;
			tweetObject["friendsCount"] = friendsCount;
			tweetObject["retweetCount"] = retweetCount;
			tweetObject["tweetType"] = tweetType;
			tweetObject["tweetMessage"] = tweetMessage;

			var chartData = [[followersCount, friendsCount, retweetCount]];

			var twitterIdRef = document.createElement("a");
			twitterIdRef.chartData = chartData;
			twitterIdRef.innerHTML = twitterId;
			twitterIdRef.href = "#";
			twitterIdRef.onclick = function() {
				createSystemULink(this.innerHTML); // Using Twitter-id to create a System-U link.
				showInfluenceBarChart(this.chartData);
			};

			var searchCustomerButton = createButton("Search", customerInfoButtonHandler, "button-generic");
			searchCustomerButton.twitterId = twitterId;

			var emailButton = createButton("Email", sendEmailButtonHandler, "button-generic");
			emailButton.tweetObject = tweetObject;

			var smsButton = createButton("SMS", sendSmsButtonHandler, "button-generic");
			smsButton.tweetObject = tweetObject;

			var offersButton = createButton("Offers", offersButtonHandler, "button-generic");
			offersButton.tweetObject = tweetObject;

			var tweetRowData = [tweetDate, twitterIdRef, userName, tweetType, tweetMessage, searchCustomerButton, emailButton, smsButton, offersButton];
			var tweetRow = insertTableRow(tweetTable, tweetRowData);
			tweets.push(tweetRowData);
		}

		if (tweets.length > 0) {
			return tweets;
		}
	}

	return null;
}

function repopulateTweetTable(tweetData) {
	if (tweetData) {
		var tweetTable = document.getElementById("tweetTable");

		// Remove all rows before inserting.
		clearTableElement(tweetTable);

		for (i=0; i<tweetData.length; i++) {
			insertTableRow(tweetTable, tweetData[i]);
		}
	}
}

function gotoNextTweetPage() {
	// Take no action in case there is no page being displayed.
	if (currentPage == 0) {
		return;
	}

	// Check if the page is available in Tweet store.
	var tweets = tweetStore[(currentPage + 1)];

	if (tweets) {
		// Update current page index.
		currentPage = currentPage + 1;

		// If Tweets are available, repopulate it.
		repopulateTweetTable(tweets);
	} else {
		// If Tweets are not available, get it from the server.
		try {
			var url = TWEET_PAGINATION_URL + (currentPage + 1);

			doHttpGet(url, nextPageDataHandler);
		} catch (e) {
			alert("Error in gotoNextTweetPage(): " + e);
		}
	}
}

function gotoPreviousTweetPage() {
	// Take no action in case there is no previous page.
	if (currentPage == 1) {
		return;
	}

	// Get previous page from Tweet store.
	var tweets = tweetStore[(currentPage - 1)];

	if (tweets) {
		currentPage = currentPage - 1;
		repopulateTweetTable(tweets);
	}
}

function setChartLabel(str) {
	document.getElementById("chartLabel").innerHTML = str;
}

function showSentimentChart() {
	if (sentimentChartData != null) {
		setChartLabel("Sentiment Chart for Tweets");
		drawPieChart("chart", sentimentChartData, true);
	}
}

function showSentimentTrendChart() {
	if (sentimentTrendData != null) {
		setChartLabel("Sentiment Trend for Tweets");
		drawDateAxisChart("chart", sentimentTrendData, true, trendChartProperties);
	}
}

function showOmsChart() {
	if (omsChartData != null) {
		setChartLabel("Operational/Marketing/Sales Tweets");
		drawPieChart("chart", omsChartData, true);
	}
}

// Admin functionality.

var addCustomerResponseHandler = function(data, status) {
	if (data) {
		console.log("addCustomerResponse: " + data);

		if (data == "success") {
			alert("The Customer has been successfully added.");

			// Clear already entered Customer details.
			document.getElementById("twitterId").value = "";
			document.getElementById("customerName").value = "";
			document.getElementById("phoneNumber").value = "";
			document.getElementById("emailId").value = "";
		} else {
			alert("Failed to add Customer. Please, try again.");
		}
	} else {
		alert("Unable to get any response from server. Please, try again.");
	}
};

var addCustomerErrorHandler = function(request, status, error) {
	console.log("Error while adding Customer: " + error);
	alert("Failed to add Customer. Please, try again.");
};

function addCustomer() {
	// Validate input.
	var twitterId = document.getElementById("twitterId").value;

	if (isStringEmpty(twitterId)) {
		alert("Please, enter Twitter Id.");
		return;
	}

	var customerName = document.getElementById("customerName").value;

	if (isStringEmpty(customerName)) {
		alert("Please, enter Customer Name.");
		return;
	}

	var phoneNumber = document.getElementById("phoneNumber").value;

	if (isStringEmpty(phoneNumber)) {
		alert("Please, enter Phone Number.");
		return;
	}

	var emailId = document.getElementById("emailId").value;

	if (isStringEmpty(emailId)) {
		alert("Please, enter Email Id.");
		return;
	}

	// Trim leading or trailing space characters.
	twitterId = trimString(twitterId);
	customerName = trimString(customerName);
	phoneNumber = trimString(phoneNumber);
	emailId = trimString(emailId);

	// Submit Customer information.
	var payloadObject = {"twitterId": twitterId, "customerName": customerName, "phoneNumber": phoneNumber, "emailId": emailId};
	var payloadString = JSON.stringify(payloadObject);
	var payload = {"data": payloadString};

	doHttpPost(ADD_CUSTOMER_URL, payload, addCustomerResponseHandler, addCustomerErrorHandler);
}