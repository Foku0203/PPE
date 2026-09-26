import { useEffect, useState } from 'react';
import type { LucideIcon } from 'lucide-react';
import {
  Activity,
  ArrowDownRight,
  ArrowUpRight,
  Bell,
  Boxes,
  Check,
  ChevronDown,
  ClipboardCheck,
  Clock3,
  HardHat,
  LayoutDashboard,
  Menu,
  PackageCheck,
  Plus,
  QrCode,
  Search,
  Settings2,
  ShieldCheck,
  Shirt,
  SlidersHorizontal,
  Sparkles,
  UserRound,
  Users,
  X,
} from 'lucide-react';

type Locale = 'TH' | 'EN' | 'MY';
type Tab = 'overview' | 'requests' | 'inventory' | 'catalog' | 'team';
type RequestStatus = 'รออนุมัติ' | 'อนุมัติแล้ว' | 'พร้อมรับของ' | 'รับสำเร็จ';

type Product = {
  id: string;
  icon: LucideIcon;
  iconClass: string;
  names: Record<Locale, string>;
  stock: number;
  unit: string;
  lifespan: string;
  issued: string;
  reorder: number;
  badge?: string;
};

type Request = {
  id: string;
  requester: string;
  department: string;
  item: string;
  quantity: number;
  reason: string;
  submitted: string;
  status: RequestStatus;
  special?: boolean;
};

const copy = {
  TH: {
    overview: 'ภาพรวม', requests: 'คำขอเบิก', inventory: 'คลัง PPE', catalog: 'แคตตาล็อก', team: 'ทีมงาน',
    hello: 'สวัสดี, คุณอรทัย', subtitle: 'นี่คือภาพรวมความปลอดภัยของโรงงานวันนี้', newRequest: 'สร้างคำขอใหม่', scan: 'สแกน QR',
    pending: 'รอการอนุมัติ', ready: 'พร้อมรับของ', stockValue: 'มูลค่าสต็อก', activeUsers: 'ผู้ใช้งานวันนี้',
    requestQueue: 'คิวคำขอที่ต้องดูแล', viewAll: 'ดูทั้งหมด', lowStock: 'รายการใกล้หมด', restock: 'จัดการสั่งซื้อ',
    recentActivity: 'กิจกรรมล่าสุด', noRequests: 'ยังไม่มีคำขอในมุมมองนี้', search: 'ค้นหา PPE, เลขที่คำขอ หรือพนักงาน...',
    approve: 'อนุมัติ', reject: 'ปฏิเสธ', size: 'ไซส์', quantity: 'จำนวน', reason: 'เหตุผล', createTitle: 'สร้างคำขอเบิก PPE',
    submit: 'ส่งคำขอ', cancel: 'ยกเลิก', chooseItem: 'เลือกอุปกรณ์', reasonDamaged: 'ชำรุด', reasonReplace: 'ครบกำหนดเปลี่ยน',
    reasonNew: 'พนักงานใหม่', scanTitle: 'สแกนเพื่อรับอุปกรณ์', scanHint: 'วาง QR Code ของคำขอไว้ในกรอบ', close: 'ปิด',
  },
  EN: {
    overview: 'Overview', requests: 'Requests', inventory: 'PPE Stock', catalog: 'Catalog', team: 'Team',
    hello: 'Good morning, Orathai', subtitle: "Here's today's safety operations pulse", newRequest: 'New request', scan: 'Scan QR',
    pending: 'Pending approval', ready: 'Ready for pickup', stockValue: 'Stock value', activeUsers: 'Active users',
    requestQueue: 'Request queue', viewAll: 'View all', lowStock: 'Low stock items', restock: 'Manage restock',
    recentActivity: 'Recent activity', noRequests: 'No requests in this view', search: 'Search PPE, request ID or employee...',
    approve: 'Approve', reject: 'Reject', size: 'Size', quantity: 'Quantity', reason: 'Reason', createTitle: 'Create PPE request',
    submit: 'Submit request', cancel: 'Cancel', chooseItem: 'Choose equipment', reasonDamaged: 'Damaged', reasonReplace: 'Replacement due',
    reasonNew: 'New employee', scanTitle: 'Scan to issue equipment', scanHint: 'Place the request QR code inside the frame', close: 'Close',
  },
  MY: {
    overview: 'ခြုံငုံသုံးသပ်ချက်', requests: 'တောင်းဆိုမှုများ', inventory: 'PPE စတော့', catalog: 'ကတ်တလောက်', team: 'အဖွဲ့',
    hello: 'မင်္ဂလာပါ၊ အိုရထိုင်း', subtitle: 'ယနေ့လုံခြုံရေးလုပ်ငန်းများ၏ အခြေအနေ', newRequest: 'တောင်းဆိုမှုအသစ်', scan: 'QR ဖတ်ရန်',
    pending: 'အတည်ပြုရန်စောင့်နေသည်', ready: 'လက်ခံရန်အသင့်', stockValue: 'စတော့တန်ဖိုး', activeUsers: 'အသုံးပြုသူများ',
    requestQueue: 'တောင်းဆိုမှုစာရင်း', viewAll: 'အားလုံးကြည့်ရန်', lowStock: 'စတော့နည်းသောပစ္စည်း', restock: 'ပြန်လည်မှာယူရန်',
    recentActivity: 'လတ်တလောလုပ်ဆောင်ချက်', noRequests: 'ဤမြင်ကွင်းတွင် တောင်းဆိုမှုမရှိပါ', search: 'PPE၊ တောင်းဆိုမှု သို့မဟုတ် ဝန်ထမ်းရှာရန်...',
    approve: 'အတည်ပြုရန်', reject: 'ငြင်းပယ်ရန်', size: 'အရွယ်', quantity: 'အရေအတွက်', reason: 'အကြောင်းပြချက်', createTitle: 'PPE တောင်းဆိုမှုဖန်တီးရန်',
    submit: 'တောင်းဆိုချက်ပေးပို့ရန်', cancel: 'ပယ်ဖျက်ရန်', chooseItem: 'ပစ္စည်းရွေးရန်', reasonDamaged: 'ပျက်စီး', reasonReplace: 'သက်တမ်းကုန်',
    reasonNew: 'ဝန်ထမ်းအသစ်', scanTitle: 'ပစ္စည်းလက်ခံရန် စကင်ဖတ်ပါ', scanHint: 'တောင်းဆိုမှု QR ကို ဘောင်အတွင်းထားပါ', close: 'ပိတ်ရန်',
  },
} as const;

const products: Product[] = [
  { id: 'helmet', icon: HardHat, iconClass: 'amber', names: { TH: 'หมวกนิรภัย', EN: 'Safety Helmet', MY: 'ဘေးကင်း ဦးထုပ်' }, stock: 128, unit: 'ชิ้น', lifespan: '730 วัน', issued: '42 วันนี้', reorder: 50 },
  { id: 'boots', icon: PackageCheck, iconClass: 'blue', names: { TH: 'รองเท้านิรภัย', EN: 'Safety Boots', MY: 'လုံခြုံရေးဖိနပ်' }, stock: 64, unit: 'คู่', lifespan: '365 วัน', issued: '18 วันนี้', reorder: 40 },
  { id: 'goggles', icon: ShieldCheck, iconClass: 'mint', names: { TH: 'แว่นตานิรภัย', EN: 'Safety Goggles', MY: 'အကာအကွယ်မျက်မှန်' }, stock: 24, unit: 'ชิ้น', lifespan: '180 วัน', issued: '31 วันนี้', reorder: 30, badge: 'ต่ำกว่า ROP' },
  { id: 'vest', icon: Shirt, iconClass: 'coral', names: { TH: 'เสื้อสะท้อนแสง', EN: 'Safety Vest', MY: 'ရောင်ပြန်အင်္ကျ' }, stock: 92, unit: 'ตัว', lifespan: '365 วัน', issued: '26 วันนี้', reorder: 30 },
  { id: 'harness', icon: Activity, iconClass: 'violet', names: { TH: 'สายรัดนิรภัย', EN: 'Safety Harness', MY: 'ပြုတ်ကျမှုကာကွယ်ရေး ခါးပတ်' }, stock: 12, unit: 'ชุด', lifespan: '1,095 วัน', issued: '4 วันนี้', reorder: 15, badge: 'ต้องตรวจ Serial' },
  { id: 'gloves', icon: ShieldCheck, iconClass: 'teal', names: { TH: 'ถุงมือนิรภัย', EN: 'Safety Gloves', MY: 'ဘေးကင်းလုံခြုံရေး လက်အိတ်' }, stock: 310, unit: 'คู่', lifespan: '90 วัน', issued: '88 วันนี้', reorder: 100 },
];

const initialRequests: Request[] = [
  { id: 'PR-240918-031', requester: 'สมชาย ใจดี', department: 'Production · Line 03', item: 'สายรัดนิรภัย', quantity: 1, reason: 'ชำรุด', submitted: '8 นาทีที่แล้ว', status: 'รออนุมัติ', special: true },
  { id: 'PR-240918-029', requester: 'Myo Min Thu', department: 'Maintenance · Zone B', item: 'รองเท้านิรภัย', quantity: 1, reason: 'พนักงานใหม่', submitted: '24 นาทีที่แล้ว', status: 'รออนุมัติ' },
  { id: 'PR-240918-026', requester: 'กมลชนก สุขใจ', department: 'Warehouse · Shift A', item: 'แว่นตานิรภัย', quantity: 2, reason: 'ชำรุด', submitted: '1 ชั่วโมงที่แล้ว', status: 'อนุมัติแล้ว' },
  { id: 'PR-240917-118', requester: 'Aung Naing', department: 'Production · Line 01', item: 'หมวกนิรภัย', quantity: 1, reason: 'ครบกำหนดเปลี่ยน', submitted: 'เมื่อวาน', status: 'พร้อมรับของ' },
];

const navItems: { id: Tab; label: keyof typeof copy.TH; icon: LucideIcon }[] = [
  { id: 'overview', label: 'overview', icon: LayoutDashboard },
  { id: 'requests', label: 'requests', icon: ClipboardCheck },
  { id: 'inventory', label: 'inventory', icon: Boxes },
  { id: 'catalog', label: 'catalog', icon: SlidersHorizontal },
  { id: 'team', label: 'team', icon: Users },
];

function tabFromPath(pathname: string): Tab {
  const path = pathname.replace(/\/$/, '');
  return path === '/requests' || path === '/inventory' || path === '/catalog' || path === '/team'
    ? path.slice(1) as Tab
    : 'overview';
}

function App() {
  const [locale, setLocale] = useState<Locale>('TH');
  const [activeTab, setActiveTab] = useState<Tab>(() => tabFromPath(window.location.pathname));
  const [requests, setRequests] = useState<Request[]>(initialRequests);
  const [showRequestModal, setShowRequestModal] = useState(false);
  const [showScanModal, setShowScanModal] = useState(false);
  const [showMobileNav, setShowMobileNav] = useState(false);
  const [toast, setToast] = useState('');
  const t = copy[locale];

  useEffect(() => {
    const syncRoute = () => setActiveTab(tabFromPath(window.location.pathname));
    window.addEventListener('popstate', syncRoute);
    return () => window.removeEventListener('popstate', syncRoute);
  }, []);

  const goTo = (tab: Tab) => {
    const pathname = tab === 'overview' ? '/' : `/${tab}`;
    if (window.location.pathname !== pathname) window.history.pushState({}, '', pathname);
    setActiveTab(tab);
    setShowMobileNav(false);
  };

  const notify = (message: string) => {
    setToast(message);
    window.setTimeout(() => setToast(''), 2800);
  };

  const updateRequest = (id: string, status: RequestStatus) => {
    setRequests((current) => current.map((request) => request.id === id ? { ...request, status } : request));
    notify(status === 'อนุมัติแล้ว' ? 'อนุมัติคำขอเรียบร้อยแล้ว' : 'อัปเดตสถานะคำขอแล้ว');
  };

  return (
    <div className="app-shell">
      <aside className={`sidebar ${showMobileNav ? 'sidebar-open' : ''}`}>
        <div className="brand-lockup">
          <div className="brand-mark"><ShieldCheck size={21} strokeWidth={2.5} /></div>
          <div><strong>protex</strong><span>SAFETY OPERATIONS</span></div>
        </div>
        <div className="workspace-switcher"><div className="plant-avatar">P</div><div><small>WORKSPACE</small><b>Plant 01 · Rayong</b></div><ChevronDown size={15} /></div>
        <nav className="main-nav">
          <p className="nav-label">COMMAND CENTER</p>
          {navItems.map(({ id, label, icon: Icon }) => <button key={id} className={`nav-item ${activeTab === id ? 'active' : ''}`} onClick={() => goTo(id)}><Icon size={18} /><span>{t[label]}</span>{id === 'requests' && <em>12</em>}</button>)}
          <p className="nav-label nav-spacer">SYSTEM</p>
          <button className="nav-item"><Settings2 size={18} /><span>ตั้งค่าระบบ</span></button>
        </nav>
        <div className="sidebar-foot"><div className="profile"><div className="profile-avatar">อ</div><div><b>อรทัย วิริยะ</b><span>Store Admin · จป.</span></div><ChevronDown size={15} /></div><div className="status-line"><span className="status-dot" /> System operational <span>99.98%</span></div></div>
      </aside>

      <main className="main-area">
        <header className="topbar"><button className="mobile-menu" onClick={() => setShowMobileNav(!showMobileNav)}><Menu size={21} /></button><div className="crumb"><span>PLANT 01</span><b>/</b><strong>{t[activeTab]}</strong></div><div className="top-actions"><div className="lang-switcher">{(['TH', 'EN', 'MY'] as Locale[]).map((item) => <button key={item} className={locale === item ? 'selected' : ''} onClick={() => setLocale(item)}>{item}</button>)}</div><button className="icon-button notification"><Bell size={19} /><i /></button><div className="top-avatar">อ</div></div></header>
        <div className="content-wrap">
          {activeTab === 'overview' && <Overview t={t} requests={requests} onNew={() => setShowRequestModal(true)} onScan={() => setShowScanModal(true)} onNavigate={goTo} onUpdate={updateRequest} />}
          {activeTab === 'requests' && <RequestsView t={t} requests={requests} onNew={() => setShowRequestModal(true)} onUpdate={updateRequest} />}
          {activeTab === 'inventory' && <InventoryView t={t} onScan={() => setShowScanModal(true)} notify={notify} />}
          {activeTab === 'catalog' && <CatalogView t={t} />}
          {activeTab === 'team' && <TeamView t={t} />}
        </div>
      </main>
      {showRequestModal && <RequestModal t={t} onClose={() => setShowRequestModal(false)} onSubmit={(item) => { setRequests((current) => [{ id: `PR-240918-0${current.length + 8}`, requester: 'อรทัย วิริยะ', department: 'EHS · Plant 01', item, quantity: 1, reason: 'พนักงานใหม่', submitted: 'เมื่อสักครู่', status: 'รออนุมัติ' }, ...current]); setShowRequestModal(false); notify('ส่งคำขอเบิกเรียบร้อยแล้ว'); }} />}
      {showScanModal && <ScanModal t={t} onClose={() => setShowScanModal(false)} onSuccess={() => { setShowScanModal(false); notify('ยืนยันรับอุปกรณ์ PR-240917-118 แล้ว'); }} />}
      {toast && <div className="toast"><Check size={17} />{toast}</div>}
    </div>
  );
}

type T = Record<keyof typeof copy.TH, string>;
function Overview({ t, requests, onNew, onScan, onNavigate, onUpdate }: { t: T; requests: Request[]; onNew: () => void; onScan: () => void; onNavigate: (tab: Tab) => void; onUpdate: (id: string, status: RequestStatus) => void }) {
  const pending = requests.filter((request) => request.status === 'รออนุมัติ');
  return <>
    <section className="hero-row"><div><div className="eyebrow"><span className="live-pulse" /> LIVE OPERATIONS · 18 SEP 2024</div><h1>{t.hello}</h1><p>{t.subtitle}</p></div><div className="hero-actions"><button className="button button-quiet" onClick={onScan}><QrCode size={17} />{t.scan}</button><button className="button button-primary" onClick={onNew}><Plus size={17} />{t.newRequest}</button></div></section>
    <section className="metrics-grid"><Metric icon={Clock3} label={t.pending} value="12" trend="+4.8%" trendUp /><Metric icon={PackageCheck} label={t.ready} value="08" trend="-12.2%" /><Metric icon={Boxes} label={t.stockValue} value="฿1.28M" trend="+8.1%" trendUp /><Metric icon={Users} label={t.activeUsers} value="184" trend="+16.4%" trendUp /></section>
    <section className="dashboard-grid"><div className="panel request-panel"><div className="panel-heading"><div><span className="section-kicker">APPROVAL WORKFLOW</span><h2>{t.requestQueue}</h2></div><button className="text-button" onClick={() => onNavigate('requests')}>{t.viewAll}<ArrowUpRight size={15} /></button></div><div className="request-list">{pending.slice(0, 3).map((request) => <RequestRow key={request.id} request={request} t={t} onUpdate={onUpdate} />)}</div></div><div className="panel stock-panel"><div className="panel-heading"><div><span className="section-kicker">INVENTORY SIGNAL</span><h2>{t.lowStock}</h2></div><button className="icon-button"><ArrowUpRight size={17} /></button></div><div className="stock-alert"><div className="alert-icon"><Activity size={18} /></div><div><b>Safety Goggles</b><span>เหลือ 24 ชิ้น · จุดสั่งซื้อ 30</span></div><strong>−20%</strong></div><div className="stock-alert critical"><div className="alert-icon"><HardHat size={18} /></div><div><b>Safety Harness</b><span>เหลือ 12 ชุด · ต้องตรวจ Serial</span></div><strong>−24%</strong></div><button className="full-link" onClick={() => onNavigate('inventory')}>{t.restock}<ArrowUpRight size={15} /></button></div></section>
    <section className="bottom-grid"><div className="panel chart-panel"><div className="panel-heading"><div><span className="section-kicker">ISSUANCE TREND</span><h2>การเบิกจ่ายรายสัปดาห์</h2></div><div className="chart-filter">Last 7 days <ChevronDown size={14} /></div></div><div className="chart-wrap"><div className="chart-y"><span>100</span><span>75</span><span>50</span><span>25</span><span>0</span></div><div className="chart"><div className="grid-line g1" /><div className="grid-line g2" /><div className="grid-line g3" /><svg viewBox="0 0 640 210" preserveAspectRatio="none"><path className="area-path" d="M0,158 C32,142 50,164 82,143 S133,135 163,151 S207,118 240,131 S286,106 320,124 S363,71 400,98 S445,82 474,104 S520,55 552,73 S598,52 640,30 L640,210 L0,210 Z" /><path className="line-path" d="M0,158 C32,142 50,164 82,143 S133,135 163,151 S207,118 240,131 S286,106 320,124 S363,71 400,98 S445,82 474,104 S520,55 552,73 S598,52 640,30" /></svg><div className="chart-labels"><span>Mon</span><span>Tue</span><span>Wed</span><span>Thu</span><span>Fri</span><span>Sat</span><span>Sun</span></div></div></div></div><div className="panel activity-panel"><div className="panel-heading"><div><span className="section-kicker">AUDIT TRAIL</span><h2>{t.recentActivity}</h2></div><button className="icon-button"><ArrowUpRight size={17} /></button></div><div className="activity-list"><ActivityItem icon={Check} color="green" title="คำขอ PR-240918-026 อนุมัติแล้ว" meta="โดย Supervisor · 12 นาทีที่แล้ว" /><ActivityItem icon={QrCode} color="blue" title="สแกนรับ Safety Helmet 1 ชิ้น" meta="Store Counter A · 24 นาทีที่แล้ว" /><ActivityItem icon={Bell} color="amber" title="แจ้งเตือน Reorder: Safety Goggles" meta="ระบบอัตโนมัติ · 41 นาทีที่แล้ว" /></div></div></section>
  </>;
}

function Metric({ icon: Icon, label, value, trend, trendUp }: { icon: LucideIcon; label: string; value: string; trend: string; trendUp?: boolean }) { return <div className="metric-card"><div className="metric-icon"><Icon size={19} /></div><span>{label}</span><strong>{value}</strong><small className={trendUp ? 'trend positive' : 'trend'}>{trendUp ? <ArrowUpRight size={13} /> : <ArrowDownRight size={13} />}{trend} <em>vs last week</em></small></div>; }
function RequestRow({ request, t, onUpdate }: { request: Request; t: T; onUpdate: (id: string, status: RequestStatus) => void }) { return <div className="request-row"><div className="person-badge">{request.requester.charAt(0)}</div><div className="request-main"><div><b>{request.requester}</b>{request.special && <span className="special-tag"><Sparkles size={11} /> Special</span>}</div><span>{request.department}</span></div><div className="request-item"><b>{request.item}</b><span>{request.quantity} {request.quantity > 1 ? 'ชิ้น' : 'ชุด'} · {request.reason}</span></div><div className="request-time">{request.submitted}</div><div className="row-actions"><button className="approve-button" title={t.approve} onClick={() => onUpdate(request.id, 'อนุมัติแล้ว')}><Check size={16} /></button><button className="reject-button" title={t.reject} onClick={() => onUpdate(request.id, 'รออนุมัติ')}><X size={16} /></button></div></div>; }
function ActivityItem({ icon: Icon, color, title, meta }: { icon: LucideIcon; color: string; title: string; meta: string }) { return <div className="activity-item"><div className={`activity-icon ${color}`}><Icon size={15} /></div><div><b>{title}</b><span>{meta}</span></div></div>; }

function RequestsView({ t, requests, onNew, onUpdate }: { t: T; requests: Request[]; onNew: () => void; onUpdate: (id: string, status: RequestStatus) => void }) { return <section><PageHeading eyebrow="REQUEST CENTER" title={t.requests} description="ติดตาม ตรวจสอบ และอนุมัติคำขอ PPE จากทุกหน่วยงาน" action={<button className="button button-primary" onClick={onNew}><Plus size={17} />{t.newRequest}</button>} /><div className="filter-row"><div className="search-box"><Search size={17} /><input placeholder={t.search} /></div><button className="filter-button"><SlidersHorizontal size={16} />ตัวกรอง<ChevronDown size={14} /></button><div className="filter-tabs"><button className="active">ทั้งหมด 24</button><button>รออนุมัติ 12</button><button>พร้อมรับ 8</button></div></div><div className="panel table-panel"><div className="table-head"><span>ผู้ขอ</span><span>รายการ</span><span>เหตุผล</span><span>ส่งเมื่อ</span><span>สถานะ</span><span /></div>{requests.map((request) => <div className="table-row" key={request.id}><div className="requester-cell"><div className="person-badge small">{request.requester.charAt(0)}</div><div><b>{request.requester}</b><span>{request.id} · {request.department}</span></div></div><div><b>{request.item}</b><span>{request.quantity} รายการ</span></div><span>{request.reason}</span><span>{request.submitted}</span><StatusPill status={request.status} /><div className="row-actions">{request.status === 'รออนุมัติ' && <button className="approve-button" onClick={() => onUpdate(request.id, 'อนุมัติแล้ว')}><Check size={16} /></button>}</div></div>)}</div></section>; }
function StatusPill({ status }: { status: RequestStatus }) { const className = status === 'รออนุมัติ' ? 'waiting' : status === 'อนุมัติแล้ว' ? 'approved' : status === 'พร้อมรับของ' ? 'ready' : 'complete'; return <span className={`status-pill ${className}`}><i />{status}</span>; }
function PageHeading({ eyebrow, title, description, action }: { eyebrow: string; title: string; description: string; action?: React.ReactNode }) { return <div className="page-heading"><div><span className="eyebrow">{eyebrow}</span><h1>{title}</h1><p>{description}</p></div>{action}</div>; }

function InventoryView({ t, onScan, notify }: { t: T; onScan: () => void; notify: (message: string) => void }) { return <section><PageHeading eyebrow="REAL-TIME STOCK CONTROL" title={t.inventory} description="ติดตามคงเหลือ, Serial/Lot และสัญญาณเติมสินค้าแบบ Real-time" action={<button className="button button-primary" onClick={onScan}><QrCode size={17} />{t.scan}</button>} /><div className="inventory-summary"><div><span>ทั้งหมดในคลัง</span><strong>630 <small>หน่วย</small></strong></div><div><span>ต่ำกว่า Reorder Point</span><strong className="red-number">2 <small>รายการ</small></strong></div><div><span>Serial/Lot tracked</span><strong>100<span className="percent">%</span></strong></div></div><div className="panel table-panel inventory-table"><div className="table-head"><span>อุปกรณ์</span><span>คงเหลือ</span><span>Reorder point</span><span>การติดตาม</span><span>สถานะ</span><span /></div>{products.map((product) => <div className="table-row" key={product.id}><div className="product-cell"><div className={`product-icon ${product.iconClass}`}><product.icon size={18} /></div><div><b>{product.names[tLocale(t)]}</b><span>{product.id.toUpperCase()} · {product.unit}</span></div></div><div className="stock-number"><b>{product.stock}</b><div className="mini-progress"><i style={{ width: `${Math.min(100, product.stock / Math.max(product.reorder, 1) * 50)}%` }} /></div></div><span>{product.reorder} {product.unit}</span><span>{product.id === 'harness' ? <><b>Serial + Lot</b><small>Inspection required</small></> : 'Lot / Expiry'}</span><StatusPill status={product.badge ? 'รออนุมัติ' : 'รับสำเร็จ'} /><button className="more-button" onClick={() => notify(`เปิดรายละเอียด ${product.names.TH}`)}>•••</button></div>)}</div></section>; }
function tLocale(t: T): Locale { return t.overview === copy.EN.overview ? 'EN' : t.overview === copy.MY.overview ? 'MY' : 'TH'; }
function CatalogView({ t }: { t: T }) { return <section><PageHeading eyebrow="PPE CATALOG · 3 LANGUAGES" title={t.catalog} description="แคตตาล็อกอุปกรณ์พร้อม Visual Icon, โควต้า และ Lifespan สำหรับทุกหน่วยงาน" action={<button className="button button-quiet"><Plus size={17} />เพิ่มอุปกรณ์</button>} /><div className="catalog-grid">{products.map((product) => <div className="catalog-card" key={product.id}><div className={`catalog-icon ${product.iconClass}`}><product.icon size={26} /></div><div className="catalog-card-body"><div className="catalog-title"><h3>{product.names[tLocale(t)]}</h3><span className="code-label">{product.id.toUpperCase()}</span></div><p>{product.names.EN}</p><div className="catalog-specs"><span><b>{product.lifespan}</b><small>Lifespan</small></span><span><b>{product.reorder} {product.unit}</b><small>Reorder Point</small></span><span><b>{product.issued}</b><small>Issued</small></span></div></div><button className="more-button">•••</button></div>)}</div></section>; }
function TeamView({ t }: { t: T }) { const team = [{ name: 'สมชาย ใจดี', role: 'Worker · Production', status: 'Active', initial: 'ส' }, { name: 'Myo Min Thu', role: 'Worker · Maintenance', status: 'Active', initial: 'M' }, { name: 'กมลชนก สุขใจ', role: 'Supervisor · Warehouse', status: 'Active', initial: 'ก' }, { name: 'อรทัย วิริยะ', role: 'Store Admin · EHS', status: 'Admin', initial: 'อ' }]; return <section><PageHeading eyebrow="PEOPLE & PERMISSIONS" title={t.team} description="จัดการผู้ใช้งาน บทบาท และขอบเขตการอนุมัติของแต่ละทีม" action={<button className="button button-primary"><Plus size={17} />เพิ่มผู้ใช้งาน</button>} /><div className="team-grid">{team.map((person) => <div className="team-card" key={person.name}><div className="team-avatar">{person.initial}</div><div><h3>{person.name}</h3><p>{person.role}</p></div><span className="online-dot" /><button className="more-button">•••</button></div>)}</div><div className="permission-note"><ShieldCheck size={22} /><div><b>Role-based access control is active</b><span>ผู้ใช้งานจะเห็นเฉพาะคำขอและข้อมูลที่อยู่ในขอบเขตสิทธิ์ของตนเอง</span></div><ArrowUpRight size={17} /></div></section>; }

function RequestModal({ t, onClose, onSubmit }: { t: T; onClose: () => void; onSubmit: (item: string) => void }) { const [selected, setSelected] = useState(products[0].names.TH); const [reason, setReason] = useState<string>(t.reasonDamaged); const locale = tLocale(t); return <div className="modal-backdrop" onMouseDown={onClose}><div className="modal" onMouseDown={(event) => event.stopPropagation()}><div className="modal-heading"><div><span className="section-kicker">NEW REQUISITION</span><h2>{t.createTitle}</h2><p>ระบบจะตรวจสอบ Quota และ Lifespan อัตโนมัติ</p></div><button className="icon-button" onClick={onClose}><X size={19} /></button></div><label>{t.chooseItem}<select value={selected} onChange={(event) => setSelected(event.target.value)}>{products.map((product) => <option key={product.id}>{product.names[locale]}</option>)}</select></label><div className="form-row"><label>{t.size}<select><option>M</option><option>L</option><option>XL</option><option>Universal</option></select></label><label>{t.quantity}<input type="number" defaultValue="1" min="1" /></label></div><label>{t.reason}<div className="reason-options">{[t.reasonDamaged, t.reasonReplace, t.reasonNew].map((item) => <button key={item} type="button" className={reason === item ? 'selected' : ''} onClick={() => setReason(item)}>{item}</button>)}</div></label><div className="modal-info"><Sparkles size={16} /><span>คำขอนี้จะถูกส่งไปยังหัวหน้างานของคุณเพื่ออนุมัติ</span></div><div className="modal-actions"><button className="button button-quiet" onClick={onClose}>{t.cancel}</button><button className="button button-primary" onClick={() => onSubmit(selected)}><Check size={16} />{t.submit}</button></div></div></div>; }
function ScanModal({ t, onClose, onSuccess }: { t: T; onClose: () => void; onSuccess: () => void }) { return <div className="modal-backdrop" onMouseDown={onClose}><div className="scan-modal" onMouseDown={(event) => event.stopPropagation()}><div className="scan-top"><div className="brand-mark"><QrCode size={21} /></div><button className="icon-button dark" onClick={onClose}><X size={19} /></button></div><div className="scan-copy"><span className="section-kicker">WAREHOUSE SCANNER</span><h2>{t.scanTitle}</h2><p>{t.scanHint}</p></div><div className="qr-frame"><div className="corner tl" /><div className="corner tr" /><div className="corner bl" /><div className="corner br" /><div className="qr-placeholder"><QrCode size={82} strokeWidth={1.2} /></div><div className="scan-beam" /></div><div className="scan-result"><div className="result-check"><Check size={16} /></div><div><b>พร้อมสแกนคำขอ</b><span>รองรับ QR จากบัตรพนักงานหรือใบคำขอ</span></div></div><button className="button scan-button" onClick={onSuccess}><QrCode size={17} />จำลองการสแกน PR-240917-118</button></div></div>; }

export default App;
