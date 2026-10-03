import fs from 'node:fs';

const file = 'src/views/BillingView.tsx';
let source = fs.readFileSync(file, 'utf8');

if (!source.includes("FastagRechargePanel")) {
  source = source.replace(
    "import { SettlementDesk } from '../components/finance/SettlementDesk';",
    "import { SettlementDesk } from '../components/finance/SettlementDesk';\nimport { FastagRechargePanel } from '../components/finance/FastagRechargePanel';"
  );
}

source = source.replace(/,\s*topUpFastag,\s*\n\s*\}/, '\n  }');
source = source.replace(/\n\s*const \[showTopUpModal, setShowTopUpModal\] = useState\(false\);\n\s*const \[topUpAmount, setTopUpAmount\] = useState\(500\);/, '');
source = source.replace(/\n\s*const handleTopUp = \(e: React\.FormEvent\) => \{[\s\S]*?\n\s*\};\n/, '\n');
source = source.replace(/\n\s*<button\n\s*onClick=\{\(\) => setShowTopUpModal\(true\)\}[\s\S]*?<\/button>/, '');
source = source.replace(/\{\/\* FASTag Toll Pool Card \*\/\}[\s\S]*?\{\/\* Invoices Ledger Table \*\/\}/, '<FastagRechargePanel />\n\n      {/* Invoices Ledger Table */}');
source = source.replace(/\n\s*\{\/\* Top-Up FASTag Balance Modal \*\/\}[\s\S]*?\n\s*<\/div>\n\s*\}\n\s*\);/, '\n    </div>\n  );');

fs.writeFileSync(file, source);
