// /src/common/supabase.js
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js/+esm';

const supabaseUrl = 'https://gdmtprrvvertulacwnqo.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdkbXRwcnJ2dmVydHVsYWN3bnFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM5Njk0NDksImV4cCI6MjA2OTU0NTQ0OX0.RDfFSHEsqyMyaunRW8ySzDus6GSrTQy4oxcWeH4GlbU';

export const supabase = createClient(supabaseUrl, supabaseKey);