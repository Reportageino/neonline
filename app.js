(() => {
  const $ = (s, root=document) => root.querySelector(s);
  const $$ = (s, root=document) => [...root.querySelectorAll(s)];
  const toggle = $('#menuToggle'), nav = $('#mainNav'), overlay = $('#mobileOverlay');
  const closeMenu = () => { nav?.classList.remove('open'); overlay?.classList.remove('show'); };
  toggle?.addEventListener('click', () => { nav?.classList.toggle('open'); overlay?.classList.toggle('show'); });
  overlay?.addEventListener('click', closeMenu); $$('.main-nav a').forEach(a => a.addEventListener('click', closeMenu));
  const themeBtn = $('#themeToggle');
  try { if (localStorage.getItem('neon-theme') === 'dark') document.body.classList.add('dark'); } catch {}
  themeBtn?.addEventListener('click', () => { document.body.classList.toggle('dark'); try { localStorage.setItem('neon-theme', document.body.classList.contains('dark')?'dark':'light'); } catch {} });
  const cfg = window.NEON_CONFIG || {};
  const configured = cfg.SUPABASE_URL && !cfg.SUPABASE_URL.includes('YOUR-PROJECT') && cfg.SUPABASE_ANON_KEY && !cfg.SUPABASE_ANON_KEY.includes('YOUR_SUPABASE');
  let clientPromise;
  async function supabase() {
    if (!configured) throw new Error('برای فعال‌سازی این قابلیت، ابتدا URL و کلید عمومی Supabase را در config.js وارد کنید.');
    if (!window.supabase) throw new Error('کتابخانه Supabase بارگذاری نشد؛ اتصال اینترنت را بررسی کنید.');
    if (!clientPromise) clientPromise = Promise.resolve(window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY));
    return clientPromise;
  }
  $$('[data-contact-form]').forEach(form => form.addEventListener('submit', async e => {
    e.preventDefault(); const msg = $('.form-message', form), btn = $('button[type="submit"]', form);
    const data = Object.fromEntries(new FormData(form).entries());
    if (msg) msg.textContent = 'در حال ثبت درخواست…'; if (btn) btn.disabled = true;
    try { const sb = await supabase(); const {error} = await sb.from('leads').insert([{name:String(data.name||'').trim(),phone:String(data.phone||'').trim(),email:String(data.email||'').trim(),service:String(data.service||'').trim(),details:String(data.details||'').trim()}]); if(error) throw error; form.reset(); if(msg) msg.textContent='درخواست شما با موفقیت ثبت شد. به‌زودی با شما تماس می‌گیریم.'; }
    catch(err) { if(msg) { msg.textContent = configured ? `ثبت درخواست انجام نشد: ${err.message || 'خطای ارتباط با پایگاه داده'}` : 'فرم آماده اتصال است؛ پس از تنظیم Supabase درخواست‌ها در پایگاه داده ذخیره می‌شوند.'; msg.style.color='#b7791f'; } }
    finally { if(btn) btn.disabled = false; }
  }));
  window.NeonApp = { supabase, configured };
})();
