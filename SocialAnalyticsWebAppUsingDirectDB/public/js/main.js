// Defining constants.
var TWEET_SEARCH_URL = "/search-tweets?searchKey=";
var TWEET_PAGINATION_URL = "/get-tweets?page=";
var SEND_EMAIL_URL = "/send-email";
var SEND_SMS_URL = "/send-sms";
var GET_CUSTOMER_INFO_URL = "/get-customer-info?twitterId=";
var GET_MATCHING_OFFERS_URL = "/get-matching-offers";
var ADD_CUSTOMER_URL = "/add-customer";
var SYSTEM_U_URL = "/personality-insight?handle=";
var SENTIMENT_ANALYSIS_URL ="/get-sentiment-analysis";

// Defining global variables.
var sentimentChartData = null;
var omsChartData = null;
var sentimentTrendData = null;
var currentPage = 0;
var tweetStore = null;

function showAlertMessage(message) {
	if (message) {
		document.getElementById("alertMessage").innerHTML = message;
		$('#alertDialog').modal('show');
	}
}

function handleSearchKeyboardEvent(keyCode) {
	if (keyCode == 13) {
		search();
	}
}

function search() {
	var searchKey = document.getElementById("searchKey").value;
	searchKey = trimString(searchKey);

	if ((searchKey != null) && (searchKey != "")) {
		currentPage = 0; // Reset current page index.
		tweetStore = {}; // Reset Tweet store.

		$('#progressbar').modal('show');
		hideElementById("noDataMessage");

		try {
			// Encode the search key before appending to URL.
			searchKey = encodeURIComponent(searchKey);
			var url = TWEET_SEARCH_URL + searchKey;

			doHttpGet(url, searchResponseHandler, searchErrorHandler);
		} catch (e) {
			$('#progressbar').modal('hide');
			showAlertMessage("Error in search(): " + e);
		}
	}
}

function enableAfterSearchTabs() {
	var tabs = document.getElementById("myTab");
	var tabItems = tabs.getElementsByTagName("li");

	for (i=0; i<tabItems.length; i++) {
		if (i == 2) {
			tabItems[i].removeAttribute("class");
			tabItems[i].classname ="active";
		} else {
			tabItems[i].removeAttribute("class");
		}
	}
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

			var chartData = {
				"followersCount": followersCount, 
				"friendsCount": friendsCount, 
				"retweetCount": retweetCount
			};

			var twitterIdRef = document.createElement("a");
			twitterIdRef.chartData = chartData;
			twitterIdRef.innerHTML = twitterId;
			twitterIdRef.href = "#";
			twitterIdRef.onclick = function() {
				createSystemULink(this.innerHTML); // Using Twitter-id to create a System-U link.
				showInfluenceBarChart(this.chartData);
			};

			var tweetSentimentIcon = createTweetSentimentIcon(tweetType);

			var searchCustomerButton = createSearchCustomerIconButton();
			searchCustomerButton.twitterId = twitterId;

			var emailButton = createEmailIconButton();
			emailButton.tweetObject = tweetObject;

			var smsButton = createSmsIconButton();
			smsButton.tweetObject = tweetObject;

			var offersButton = createOffersIconButton();
			offersButton.tweetObject = tweetObject;

			var tweetRowData = [tweetDate, twitterIdRef, userName, 
				tweetSentimentIcon, tweetMessage, searchCustomerButton, 
				emailButton, smsButton, offersButton];
			var tweetRow = insertTableRow(tweetTable, tweetRowData);

			tweets.push(tweetRowData);
		}

		if (tweets.length > 0) {
			return tweets;
		}
	}

	return null;
}

function createSystemULink(parameters) {
	if (parameters) {
		var frameSrc = SYSTEM_U_URL + parameters;
		$('iframe').attr("src", frameSrc);
	}
}

function showPersonalityInsight(tab) {
	$('.nav-tabs a[href="#Personality"]').tab('show');
	$('#influenceChartDialog').modal('hide');
}

function createSearchCustomerIconButton() {
	var span = createSpan({
		"class": "glyphicon glyphicon-search",
		"aria-hidden": "true"
	});

	var link = createLink(getIconButtonLinkAttributes());
	link.appendChild(span);

	link.onclick = function() {
		document.getElementById("customerTwitterId").value = this.twitterId;
		$('#customerSearchDialog').modal('show');
	};

	return link;
}

function createEmailIconButton() {
	var span = createSpan({
		"class": "glyphicon glyphicon-envelope",
		"aria-hidden": "true"
	});

	var link = createLink(getIconButtonLinkAttributes());
	link.appendChild(span);
	link.onclick = sendEmailButtonHandler;

	return link;
}

function createSmsIconButton() {
	var span = createSpan({
		"class": "glyphicon glyphicon-comment",
		"aria-hidden": "true"
	});

	var link = createLink(getIconButtonLinkAttributes());
	link.appendChild(span);
	link.onclick = sendSmsButtonHandler;

	return link;
}

function createOffersIconButton() {
	var span = createSpan({
		"class": "glyphicon glyphicon-gift",
		"aria-hidden": "true"
	});

	var link = createLink(getIconButtonLinkAttributes());
	link.appendChild(span);
	link.onclick = offersButtonHandler;

	return link;
}

function createTweetSentimentIcon(tweetType) {
	var span = null;

	if (tweetType == "good") {
		span = createSpan({
			"class": "glyphicon glyphicon-thumbs-up green",
			"aria-hidden": "true"
		});
	} else if (tweetType == "bad") {
		span = createSpan({
			"class": "glyphicon glyphicon-thumbs-down red",
			"aria-hidden": "true"
		});
	} else if (tweetType == "indifferent") {
		span = createSpan({
			"class": "glyphicon glyphicon-hand-right",
			"aria-hidden": "true"
		});
	} else {
		span = createSpan({
			"class": "glyphicon glyphicon-question-sign", 
			"aria-hidden": "true"
		});
	}

	var link = createLink(getIconButtonLinkAttributes());
	link.appendChild(span);

	return link;
}

function getIconButtonLinkAttributes() {
	return {
		"text": "", 
		"href": "#", 
		"style": "font-size:x-large", 
		"data-toggle": "modal"
	};
}

function showInfluenceBarChart(chartData) {
	var data = [
		['Count', 'value', {role: 'style'}], 
		['Followers Count', chartData["followersCount"], '#9E9EF9'], 
		['Friends Count', chartData["friendsCount"], '#F0ED48'], 
		['Retweet Count', chartData["retweetCount"], '#69ED5C']
	];

	drawBarChart("influenceChart", data, "Follower Chart");
	$('#influenceChartDialog').modal('show');
}

function showSentimentChart() {
	drawPieChart("sentimentChart", sentimentChartData);
}

function showOmsChart() {
	drawPieChart("omsChart", omsChartData);
}

function showSentimentTrendChart() {
	drawDateAxisChart("sentimentTrendChart", sentimentTrendData);
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
			showAlertMessage("Error in gotoNextTweetPage(): " + e);
		}
	}
}

// App event and Data handlers.
var searchResponseHandler = function(data, status) {
	if (data) {
		var sentimentData = data.sentimentChartData;

		if (sentimentData) {
			sentimentChartData = [
				['Sentiment', 'Value'], 
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
				['Type', 'Value'], 
				["Marketing", omsData.marketing], 
				["Operations", omsData.operations], 
				["Sales", omsData.sales]
			];
		} else {
			omsChartData = null;
		}

		var trendData = data.sentimentTrendData;

		if (trendData) {
			sentimentTrendData = [['Date', 'Good', 'Bad', 'Indifferent']];
			var goodSentiments = trendData.good;
			var badSentiments = trendData.bad;
			var indifferentSentiments = trendData.indifferent;
			var sentimentDateMap = {};

			if (goodSentiments) {
				for (var key in goodSentiments) {
					// Getting the sentiments array for the date indicated by the 'key'.
					var dateSpecificSentiments = sentimentDateMap[key];

					// If the sentiments array doesn't exist, create it.
					if (!dateSpecificSentiments) {
						// Add the date indicated by the 'key' as the first element 
						// and fill the remaining with 0 for Good, Bad and Indifferent sentiments.
						dateSpecificSentiments = [key, 0, 0, 0];

						// Map the sentiments array to the date indicated by the 'key'.
						sentimentDateMap[key] = dateSpecificSentiments;
					}

					// Populate only the Good sentiment.
					dateSpecificSentiments[1] = goodSentiments[key];
				}
			}

			if (badSentiments) {
				for (var key in badSentiments) {
					// Getting the sentiments array for the date indicated by the 'key'.
					var dateSpecificSentiments = sentimentDateMap[key];

					// If the sentiments array doesn't exist, create it.
					if (!dateSpecificSentiments) {
						// Add the date indicated by the 'key' as the first element 
						// and fill the remaining with 0 for Good, Bad and Indifferent sentiments.
						dateSpecificSentiments = [key, 0, 0, 0];

						// Map the sentiments array to the date indicated by the 'key'.
						sentimentDateMap[key] = dateSpecificSentiments;
					}

					// Populate only the Bad sentiment.
					dateSpecificSentiments[2] = badSentiments[key];
				}
			}

			if (indifferentSentiments) {
				for (var key in indifferentSentiments) {
					// Getting the sentiments array for the date indicated by the 'key'.
					var dateSpecificSentiments = sentimentDateMap[key];

					// If the sentiments array doesn't exist, create it.
					if (!dateSpecificSentiments) {
						// Add the date indicated by the 'key' as the first element 
						// and fill the remaining with 0 for Good, Bad and Indifferent sentiments.
						dateSpecificSentiments = [key, 0, 0, 0];

						// Map the sentiments array to the date indicated by the 'key'.
						sentimentDateMap[key] = dateSpecificSentiments;
					}

					// Populate only the Indifferent sentiment.
					dateSpecificSentiments[3] = indifferentSentiments[key];
				}
			}

			// Add the consolidated date specific sentiments.
			for (var key in sentimentDateMap) {
				sentimentTrendData.push(sentimentDateMap[key]);
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

		enableAfterSearchTabs();
		// Make Leads tab active.
		$('.nav-tabs a[href="#Leads"]').tab('show').addClass("active");
		$('#progressbar').modal('hide');

		showSentimentChart();
		showOmsChart();
		showSentimentTrendChart();
	} else {
		$('#progressbar').modal('hide');
		showElementById("noDataMessage");
	}
};

var searchErrorHandler = function(request, status, error) {
	$('#progressbar').modal('hide');
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

var customerInfoButtonResponseHandler = function(data, status) {
	$('#customerSearchDialog').modal('hide');

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

				showAlertMessage(message);
				return;
			}
		}
	}

	showAlertMessage("Customer does not exist.");
}

var customerInfoErrorHandler = function(request, status, error) {
	$('#customerSearchDialog').modal('hide');
	console.log("Error while getting customer info: " + error);
	showAlertMessage("Temporarily unable to access customer details. Please try again later.");
};

function getCustomerInfo() {
	var twitterId = document.getElementById("customerTwitterId").value;

	if (!isStringEmpty(twitterId)) {
		twitterId = twitterId.toLowerCase();
		var url = GET_CUSTOMER_INFO_URL + twitterId;
		doHttpGet(url, customerInfoButtonResponseHandler, customerInfoErrorHandler);
	}
}

var emailResponseHandler = function(data, status) {
	if (data) {
		showAlertMessage(data);
	} else {
		showAlertMessage("Email request sent successfully.");
	}
};

var emailErrorHandler = function(request, status, error) {
	console.log("Error while sending Email: " + error);
	showAlertMessage("Temporarily unable to access the Email service due to network problem. Please try again later.");
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
		showAlertMessage(data);
	} else {
		showAlertMessage("SMS request sent successfully.");
	}
};

var smsErrorHandler = function(request, status, error) {
	console.log("Error while sending SMS: " + error);
	showAlertMessage("Temporarily unable to access the SMS service due to network problem. Please try again later.");
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

	// Show No offers available message alert.
	showElementById("offersAlert");
	hideElementById("offersTable");
	hideElementById("offerFooter");
	$('#offersDialog').modal('show');
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

				hideElementById("offersAlert");
				showElementById("offersTable");
				showElementById("offerFooter");
				$('#offersDialog').modal('show');
				return;
			}
		}

		clearInnerHtml(table);

		// Show No offers available message alert.
		showElementById("offersAlert");
		hideElementById("offersTable");
		hideElementById("offerFooter");
		$('#offersDialog').modal('show');
	}
}

var offersButtonHandler = function() {
	var tweetObject = this.tweetObject;
	var twitterId = tweetObject["twitterId"];
	var tweetMessage = tweetObject["tweetMessage"];
	var userLocation = tweetObject["userLocation"];

	// ============ Skipping customer check ============
	// ============ Always assuming Tweeter is not a customer ==============
	// Get offers relevant to the Tweet user.
	var payloadObject = {"tweet": tweetMessage, "location": userLocation, "iscustomer": false};
	var payloadString = JSON.stringify(payloadObject);
	var payload = {"data": payloadString};

	doHttpPost(GET_MATCHING_OFFERS_URL, payload, offersResponseHandler, offersErrorResponseHandler);
	return;
	// =================================================

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

// Sentiment analysis.

function createSentiButton(label, styleClassName, score, type){
	 var spanTag = document.createElement("span");
	 
 	if (type == "positive"){
 		spanTag.className ="glyphicon glyphicon-thumbs-up green";
 	} else if (type == "negative"){
 		spanTag.className ="glyphicon glyphicon-thumbs-down red";
 	} else if (type == "neutral"){
 		spanTag.className ="glyphicon glyphicon glyphicon-hand-right";
 	}

 	spanTag.dataToggle="tooltip";
 	spanTag.dataPlacement="left";
 	spanTag.title= score;
 	spanTag.ariaHidden = "true";

 	var alink = document.createElement("a");
 	alink.style = "font-size:x-large";
 	alink.dataToggle="tooltip";
 	alink.href = "#";
	alink.innerHTML = "";
	alink.appendChild(spanTag);

	return alink;
}

var sentimentAnalysisResponseHandler = function(data, status) {
	if (data) {
		var jsonDataObject = fromJsonString(data);
		var json = jsonDataObject.data;
		var count = json.length;
		var sentiTable = document.getElementById("sentimentTable");
         
		// Remove all rows before inserting.
		clearTableElement(sentiTable);

		for (var i=0; i<count; i++) {
			var str = JSON.stringify(json[i], null, 2);
			var url = json[i].uri;

			var sentiUrl = document.createElement("a");
			sentiUrl.innerHTML = url;
			sentiUrl.href = url;
			sentiUrl.target="_blank";
			sentiUrl.classname ="sentialignment";

			var target =  json[i].target;
			target = decodeURIComponent(target);
			var score =  json[i].score;
			var type = json[i].type;
			var scoreButton = createSentiButton("scoreType", "glyphicon-stop", score, type);
			var sentiRowData = [sentiUrl,target,scoreButton];
			var sentiRow = insertTableRow(sentiTable,sentiRowData);
		}
	}

	$("#checkingmodal").modal('hide');
};

var sentimentAnalysisErrorHandler = function(request, status, error) {
	$("#checkingmodal").modal('hide');
	alert("Unable to get sentiments !");
};

function doSentimentAnalysisOnWebsites() {
	var linkText = document.getElementById("websitesToAnalyze").value;

	if (isStringEmpty(linkText)) {
		alert("Please enter the list of websites to analyze.");
		return;
	}

	$("#checkingmodal").modal('show');
	var searchString = document.getElementById("searchKey").value;
	var websitesToAnalyze = [];
	var sentimentAnalysisRequest = {
		"searchKey": searchString, 
		"websitesToAnalyze": websitesToAnalyze
	};

	var links = linkText.split("\n");
	
	for (var i=0; i<links.length; i++) {
		var link = trimString(links[i]);
		websitesToAnalyze.push(link);
	}

	var sentimentAnalysisRequestString = JSON.stringify(sentimentAnalysisRequest);
	var sentimentAnalysisRequestPayload = {"data": sentimentAnalysisRequestString};
	 
	if (!isStringEmpty(searchString)) {
		doHttpPost(SENTIMENT_ANALYSIS_URL, sentimentAnalysisRequestPayload, 
			sentimentAnalysisResponseHandler, sentimentAnalysisErrorHandler);
	}
}

// Admin functionality.
var addCustomerResponseHandler = function(data, status) {
	if (data) {
		console.log("addCustomerResponse: " + data);

		if (data == "success") {
			showAlertMessage("The Customer has been successfully added.");

			// Clear already entered Customer details.
			document.getElementById("twitterId").value = "";
			document.getElementById("customerName").value = "";
			document.getElementById("phoneNumber").value = "";
			document.getElementById("emailId").value = "";
		} else {
			showAlertMessage("Failed to add Customer. Please, try again.");
		}
	} else {
		showAlertMessage("Unable to get any response from server. Please, try again.");
	}
};

var addCustomerErrorHandler = function(request, status, error) {
	console.log("Error while adding Customer: " + error);
	showAlertMessage("Failed to add Customer. Please, try again.");
};

function addCustomer() {
	// Validate input.
	var twitterId = document.getElementById("twitterId").value;

	if (isStringEmpty(twitterId)) {
		showAlertMessage("Please, enter Twitter Id.");
		return;
	}

	var customerName = document.getElementById("customerName").value;

	if (isStringEmpty(customerName)) {
		showAlertMessage("Please, enter Customer Name.");
		return;
	}

	var phoneNumber = document.getElementById("phoneNumber").value;

	if (isStringEmpty(phoneNumber)) {
		showAlertMessage("Please, enter Phone Number.");
		return;
	}

	var emailId = document.getElementById("emailId").value;

	if (isStringEmpty(emailId)) {
		showAlertMessage("Please, enter Email Id.");
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