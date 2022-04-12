// start screen
document.querySelectorAll('.modal-button').forEach(function(el) {
    el.addEventListener('click', function() {
      var target = document.querySelector(el.getAttribute('data-target'));
      
      target.classList.add('is-active');
      target.querySelector('.modal-trigger-close').addEventListener('click',   function() {
          target.classList.remove('is-active');
      });
    });
});


function gameEnd() {
    $("#gameOver").click();

    $("#gameOver").on('click', function(e) {
        e.preventDefault();
        isPaused = true;
    });
};


// food is chosen
$("nav > .button").on('click', function(){
    console.log('Food was clicked.');
});


$(document).ready(function(){

    // open start screen on load
    $("#gameInit").click();

    // starting the game
    $("#gameStart").on('click', function() {
        // e.preventDefault();
        // isPaused = false;

        // game timer
        var timeLeft = 4;
        var isPaused = false;
        var textLeft = document.getElementById('gameTime');
        var progressLeft = document.getElementById("progressBar"); 
        var timerId = setInterval(gameCountdown, 1000);
        function gameCountdown() {
            if (timeLeft == -1 || isPaused == true) {
            // if (timeLeft == -1) {
                clearTimeout(timerId);
                gameEnd();
            } else {
                console.log('Game has begun!');
                textLeft.innerHTML = timeLeft;
                progressLeft.setAttribute("value", timeLeft);
                timeLeft--;
            }
        }

        gameCountdown();
        console.log('Game has started!');
    });

    // blinking
    setInterval(function(){ 
        console.log('> blink <');
        $("#hiSlats > .slats-head").addClass("slats-blink");
        $("#hiSlats > .slats-head").removeClass("slats-resting");

        setTimeout(function () { 
            $("#hiSlats > .slats-head").addClass("slats-resting");
            $("#hiSlats > .slats-head").removeClass("slats-blink");
        }, 500);
    }, 5000);
});