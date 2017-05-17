(function(){
  var loginForm = document.querySelector('.login-form');
  if(loginForm){
    var input = loginForm.querySelectorAll('.input');
    for(var i = 0; i < 2; i++){
      input[i].addEventListener('blur', function(){
        var val = this.value;
        if(val.trim() != "") {
          this.classList.add('focus');
        } else {
          this.classList.remove('focus');
        }
      })
    }
  }
})();