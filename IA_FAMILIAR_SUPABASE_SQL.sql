
-- IA familiar: módulo activable por familia.
-- Ejecuta esto después de sustituir el lib si quieres que aparezca como opción en familias existentes.

insert into public.family_modules (family_id, module_key, enabled, sort_order)
select f.id, 'family_ai', false, 45
from public.families f
on conflict (family_id, module_key) do nothing;

-- Si usas una función ensure_default_family_modules propia, añade también:
-- ('family_ai', false, 45)
-- en la lista de módulos por defecto.
