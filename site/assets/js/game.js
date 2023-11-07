// session id
var ulid = "";
var highScore = "";
var fetchedHighscore = 0;

// This is all for module counting
var buttonPresses = 0;
var timerTicks = 0;

function resetModCounter() {
  fetchedHighscore = 0;
  buttonPresses = 0;
  timerTicks = 0;
}

// start screen
document.querySelectorAll('.modal-button').forEach(function (el) {
  el.addEventListener('click', function () {
    var target = document.querySelector(el.getAttribute('data-target'));

    target.classList.add('is-active');
    target.querySelector('.modal-trigger-close').addEventListener('click', function () {
      target.classList.remove('is-active');
    });
  });
});

function setScoreboard() {
  // get results from /scoreboard?ulid=${ulid}
  fetch(`/score?ulid=${ulid}`).then(
    response => response.json()
  ).then(data => {
    $("#scoreTotal").text(data.total);
    $("#scoreFinal").text(data.total);
  })
}

function isHighscore() {
  fetch('/highscore', {
    method: 'POST',
    body: JSON.stringify({
      "score": parseInt($("#scoreFinal").text()),
      "ulid": ulid,
      "username": ""
    })
  }).then(
    response => response.json()
  ).then(data => {
    fetchedHighscore++;
    console.log(data);
    highScore = data.high_score_table;
    if (data.is_high_score) {
      console.log("It's a highscore")
      showHighscores();
      $("#promptName").show();
    } else {
      console.log("It's not a highscore")
      showHighscores();
    }
  })
}

function showHighscores() {
  document.getElementById("highScoresList").textContent = ''
  highScore.forEach(element => {
    console.log(element)
    var dt = document.createElement("dt")
    if (element.ulid === ulid && element.username !== '') {
      dt.style.fontWeight = 'bold'
      dt.style.background = '#FFFFFF'
      dt.style.color = '#1A2A60'
    }
    dt.innerHTML = element.username
    var dd = document.createElement("dd")
    if (element.ulid == ulid) {
      dd.style.fontWeight = 'bold'
      dd.style.background = '#FFFFFF'
      dd.style.color = '#1A2A60'
    }
    dd.innerHTML = element.score
    document.getElementById("highScoresList").appendChild(dt)
    document.getElementById("highScoresList").appendChild(dd)
  });
}

$("#submitName").on('click', function () {
  fetch('/highscore', {
    method: 'POST',
    body: JSON.stringify({
      "score": parseInt($("#scoreFinal").text()),
      "ulid": ulid,
      "username": $("#yourName").val()
    })
  }).then(
    response => response.json()
  ).then(data => {
    console.log(data);
    highScore = data.high_score_table;
    showHighscores();
    $("#promptName").hide();
  })
})

function gameEnd() {
  console.log('Game over');

  // get results from /scoreboard?ulid=${ulid}
  setScoreboard();

  // check highscores
  isHighscore()

  function introReset() {
    $(".intro-one").hide();
    $(".intro-two").hide();
    $(".pet").show();
  };

  introReset();

  $("#gameOver").click();
  $("#highScores").show();
  $(".cat-bubble").hide();
};

// starting the game
function setup() {
  // Let's make sure all highscore data and UI is gone
  $("#highScores").hide();
  document.getElementById("highScoresList").textContent = ''
  highScore = ""
  resetModCounter()
  // get the data
  // https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch
  fetch('/session').then(
    response => response.json()
  ).then(data => {
    console.log(data);
    displayMorsels(data);
    setScoreboard();
  })

  // game timer
  var timeLeft = 30;
  var isPaused = false;
  var textLeft = document.getElementById('gameTime');
  var progressLeft = document.getElementById("progressBar");
  var timerId = setInterval(gameCountdown, 1000);
  function gameCountdown() {
    timerTicks++;
    countWasmModules();
    if (timeLeft == -1 || isPaused == true) {
      // if (timeLeft == -1) {
      clearTimeout(timerId);
      gameEnd();
      $("#whiskerStage").addClass('waiting').removeClass('gametime').removeClass('choose-ninja').removeClass('choose-slats')
    } else {
      textLeft.innerHTML = timeLeft;
      progressLeft.setAttribute("value", timeLeft);
      timeLeft--;
      $(".cat-bubble").show();
      $("#whiskerStage").addClass('gametime').removeClass('waiting');
      setScoreboard();
    }
    $()
  }

  $(".intro-two").hide();

  gameCountdown();
  console.log('Game has started!');
};

// Count how many Wasm modules were executed
function countWasmModules() {
  var score = parseInt($("#scoreTotal").text());
  // Hard coded count
  var staticAssetCount = 25;

  var mods = score + buttonPresses + timerTicks + staticAssetCount + fetchedHighscore;
  console.log("counted wasm modules");
  $("#modCount").text(mods);

}

// render the data
// https://w3collective.com/fetch-display-api-data-javascript/
function displayMorsels(data) {
  ulid = data.id

  data.menu.forEach(function (morsel) {
    const morselName = morsel.demand;
    const morselTime = morsel.offset;

    setTimeout(function () {
      console.log(morselName + " demand! for " + morselTime + " milliseconds.");

      $("#whiskerStage").removeClass("beef chicken fish veg");
      $("#whiskerStage").addClass(morselName);

      // remove correct class from all buttons
      $("nav > .button.correct").removeClass('correct');

      // set class to correct on button
      $(`nav > .button.${morselName}`).addClass('correct');

    }, morselTime);
  });
}

// food is chosen
$("nav > .button").on('click', function (i, e) {
  buttonPresses++;
  console.log("button pressed");
  food = $(this).attr('id');

  if ($(this).hasClass('correct')) {
    fetch(`/tally?ulid=${ulid}&food=${food}&correct=true`).then(
      response => console.log(response)

    );

    var nYum = '<span class="yum"></span>';
    $(this).append(nYum);

    $(".slats-head").removeClass("slats-eating slats-eating2 slats-huh");
    $(".slats-head").addClass("slats-eating2").delay(100).queue(function () {
      $(this).removeClass("slats-eating2");
      $(this).dequeue();
    });


  } else {

    fetch(`/tally?ulid=${ulid}&food=${food}&correct=false`).then(
      response => console.log(response)
    );

    var nNope = '<span class="nope"></span>';
    $(this).append(nNope);

    $(".slats-head").removeClass("slats-eating slats-eating2 slats-huh");
    $(".slats-head").addClass("slats-huh").delay(100).queue(function () {
      $(this).removeClass("slats-huh");
      $(this).dequeue();
    });

  };

});

// Food is chosen by key-press
window.onkeydown = function (event) {
  console.log(event.keyCode)
  switch (event.keyCode) {
    case 68: // D key
      food = 'beef'
      console.log('beef pressed')
      break;
    case 87: // W key
      food = 'fish'
      console.log('fish pressed')
      break;
    case 65: // A key
      food = 'veg'
      console.log('veg pressed')
      break;
    case 83: // S key
      food = 'chicken'
      console.log('chicken pressed')
      break;
    default:
      console.log("Useless key pressed...")
  }

  if ($(`#${food}`).hasClass('correct')) {
    fetch(`/tally?ulid=${ulid}&food=${food}&correct=true`).then(
      response => console.log(response)
    );

    $(".slats-head").removeClass("slats-eating slats-eating2 slats-huh");
    $(".slats-head").addClass("slats-eating2").delay(100).queue(function () {
      $(this).removeClass("slats-eating2");
      $(this).dequeue();
    });
  } else {

    fetch(`/tally?ulid=${ulid}&food=${food}&correct=false`).then(
      response => console.log(response)
    );

    $(".slats-head").removeClass("slats-eating slats-eating2 slats-huh");
    $(".slats-head").addClass("slats-huh").delay(100).queue(function () {
      $(this).removeClass("slats-huh");
      $(this).dequeue();
    });

  };
};

$(document).ready(function () {

  // open start screen on load
  $("#whiskerStage").addClass('waiting');
  $("#gameInit").click();
  $("#highScores").hide();

  $(".start-game").on('click', function () {
    setup();

    if ($(this).hasClass('start-slats')) {
      $("#whiskerStage").addClass('choose-slats');
    };
    if ($(this).hasClass('start-ninja')) {
      $("#whiskerStage").addClass('choose-ninja');
    };
  });

  $("#startOver").on('click', function () {
    $("#gameInit").click();
    $(".intro-one").hide();
    $(".intro-two").show();
    $(".pet").show();
  });

  $("#introOne").on('click', function () {
    $(".intro-one").hide();
    $(".intro-two").show();
    $(".pet").show();
  });


  // blinking
  setInterval(function () {
    if ($("#whiskerStage").hasClass("waiting")) {
      $("#hiSlats > .slats-head").addClass("slats-blink");
      $("#hiSlats > .slats-head").removeClass("slats-resting");

      setTimeout(function () {
        $("#hiSlats > .slats-head").addClass("slats-resting");
        $("#hiSlats > .slats-head").removeClass("slats-blink");
      }, 500);
    };
  }, 3000);

  countWasmModules();

});
