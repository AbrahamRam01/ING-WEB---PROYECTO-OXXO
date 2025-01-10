document.getElementById('registrationForm').addEventListener('submit', function(event) {
    // Evitar el envío del formulario por defecto
    event.preventDefault();
  
    // Obtener los valores de los campos
    const name = document.getElementById('nombreUsuario').value.trim();
    const password = document.getElementById('contraseña').value.trim();
  
    // Variables para los errores
    let isValid = true;
    const nameError = document.getElementById('nameError');
    const passwordError = document.getElementById('passwordError');
  
    // Limpiar mensajes de error previos
    nameError.textContent = '';
    emailError.textContent = '';
    passwordError.textContent = '';
  
    // Validar el nombre
    if (name === '') {
      nameError.textContent = 'El nombre es obligatorio.';
      isValid = false;
    }
  
    // Validar la contraseña
    if (password === '') {
      passwordError.textContent = 'La contraseña es obligatoria.';
      isValid = false;
    } else if (password.length < 8) {
      passwordError.textContent = 'La contraseña debe tener al menos 8 caracteres.';
      isValid = false;
    }
  
    // Si todos los campos son válidos, envía el formulario
    if (isValid) {
      alert('Formulario enviado correctamente.');
      this.submit(); 
    }
  });
  