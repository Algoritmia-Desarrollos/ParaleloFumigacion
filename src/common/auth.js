import { supabase } from './supabase.js';

export function getCurrentUser() {
  try {
    const user = localStorage.getItem('user');
    return user ? JSON.parse(user) : null;
  } catch (e) {
    console.error("Error al obtener el usuario de localStorage:", e);
    return null;
  }
}

export async function login(email, password) {
  // 1. Intenta iniciar sesión en el sistema de Auth de Supabase
  const { data: loginData, error: loginError } = await supabase.auth.signInWithPassword({
    email: email,
    password: password,
  });

  if (loginError) {
    throw new Error('Credenciales incorrectas o el usuario no existe.');
  }
  
  if (!loginData.user) {
    throw new Error("No se pudo verificar el usuario. Inténtalo de nuevo.");
  }

  // 2. Si el login es exitoso, busca los datos básicos del perfil en tu tabla 'usuarios'
  const { data: userData, error: userError } = await supabase
    .from('usuarios')
    .select('role, nombre, apellido')
    .eq('id', loginData.user.id)
    .single();
  
  if (userError) {
    await supabase.auth.signOut();
    throw new Error('El perfil del usuario no fue encontrado en la base de datos.');
  }

  // 3. (NUEVO) En una segunda consulta, buscamos los clientes asignados a este usuario
  let assignedClientIds = [];
  if (userData.role === 'operario' || userData.role === 'supervisor') {
    const { data: clienteData, error: clienteError } = await supabase
      .from('operario_clientes')
      .select('cliente_id')
      .eq('operario_id', loginData.user.id);
    
    if (clienteError) {
      console.error("No se pudieron cargar los clientes asignados:", clienteError);
    } else {
      assignedClientIds = clienteData.map(c => c.cliente_id);
    }
  }

  // 4. Guardamos toda la información en el almacenamiento local
  const userToStore = {
    email: loginData.user.email,
    id: loginData.user.id,
    nombre: userData.nombre,
    apellido: userData.apellido,
    role: userData.role,
    cliente_ids: assignedClientIds
  };
  localStorage.setItem('user', JSON.stringify(userToStore));
  
  return userToStore;
}

export async function logout() {
  await supabase.auth.signOut();
  localStorage.removeItem('user');
  window.location.href = '/index.html';
}