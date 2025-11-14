import { execSync } from 'child_process'
import fs from 'fs'
import path from 'path'

// 在 dist 目录创建 .nojekyll 文件
const distPath = path.resolve(process.cwd(), 'dist')
const nojekyllPath = path.join(distPath, '.nojekyll')

if (fs.existsSync(distPath)) {
  fs.writeFileSync(nojekyllPath, '', 'utf8')
  console.log('✅ Created .nojekyll file in dist/')
} else {
  console.error('❌ dist directory not found!')
  process.exit(1)
}
