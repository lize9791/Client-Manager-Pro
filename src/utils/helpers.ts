/**
 * 格式化日期
 */
export function formatDate(date: string | Date, format: string = 'YYYY-MM-DD'): string {
  const d = typeof date === 'string' ? new Date(date) : date

  const year = d.getFullYear()
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  const hours = String(d.getHours()).padStart(2, '0')
  const minutes = String(d.getMinutes()).padStart(2, '0')
  const seconds = String(d.getSeconds()).padStart(2, '0')

  return format
    .replace('YYYY', String(year))
    .replace('MM', month)
    .replace('DD', day)
    .replace('HH', hours)
    .replace('mm', minutes)
    .replace('ss', seconds)
}

/**
 * 格式化文件大小
 */
export function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 B'

  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))

  return `${(bytes / Math.pow(k, i)).toFixed(2)} ${sizes[i]}`
}

/**
 * 验证邮箱
 */
export function validateEmail(email: string): boolean {
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return re.test(email)
}

/**
 * 验证手机号
 */
export function validatePhone(phone: string): boolean {
  // 支持国际格式和中国手机号
  const re = /^[\d\s\-+()]+$/
  return re.test(phone) && phone.replace(/\D/g, '').length >= 7
}

/**
 * 生成随机 ID
 */
export function generateId(prefix: string = ''): string {
  const timestamp = Date.now().toString(36)
  const random = Math.random().toString(36).substring(2, 8)
  return `${prefix}${timestamp}${random}`
}

/**
 * 防抖函数
 */
export function debounce<T extends (...args: any[]) => any>(
  func: T,
  wait: number
): (...args: Parameters<T>) => void {
  let timeout: ReturnType<typeof setTimeout> | null = null

  return function (this: any, ...args: Parameters<T>) {
    if (timeout) clearTimeout(timeout)
    timeout = setTimeout(() => func.apply(this, args), wait)
  }
}

/**
 * 节流函数
 */
export function throttle<T extends (...args: any[]) => any>(
  func: T,
  wait: number
): (...args: Parameters<T>) => void {
  let timeout: ReturnType<typeof setTimeout> | null = null
  let previous = 0

  return function (this: any, ...args: Parameters<T>) {
    const now = Date.now()
    const remaining = wait - (now - previous)

    if (remaining <= 0 || remaining > wait) {
      if (timeout) {
        clearTimeout(timeout)
        timeout = null
      }
      previous = now
      func.apply(this, args)
    } else if (!timeout) {
      timeout = setTimeout(() => {
        previous = Date.now()
        timeout = null
        func.apply(this, args)
      }, remaining)
    }
  }
}

/**
 * 深拷贝
 */
export function deepClone<T>(obj: T): T {
  if (obj === null || typeof obj !== 'object') return obj
  if (obj instanceof Date) return new Date(obj.getTime()) as any
  if (obj instanceof Array) return obj.map(item => deepClone(item)) as any
  if (obj instanceof Object) {
    const clonedObj: any = {}
    for (const key in obj) {
      if (obj.hasOwnProperty(key)) {
        clonedObj[key] = deepClone(obj[key])
      }
    }
    return clonedObj
  }
  return obj
}

/**
 * 下载文件
 */
export function downloadFile(content: string, fileName: string, mimeType: string = 'text/plain') {
  const blob = new Blob([content], { type: mimeType })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = fileName
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  URL.revokeObjectURL(url)
}

/**
 * 从 URL 下载文件
 */
export function downloadFromUrl(url: string, fileName: string) {
  const link = document.createElement('a')
  link.href = url
  link.download = fileName
  link.target = '_blank'
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
}

/**
 * 获取客户状态标签
 */
export function getStatusLabel(status: string): string {
  const statusMap: Record<string, string> = {
    sample_won: '样品已成交',
    negotiating: '洽谈中',
    in_production: '排产中',
    completed: '已完成',
    new_round: '新一轮洽谈',
    won_by_others: '已被他人成交',
    potential: '潜在客户',
    high_value: '高价值客户',
    no_response: '无回复',
    not_executable: '不可执行',
    low_priority: '低优先级'
  }
  return statusMap[status] || status
}

/**
 * 获取客户状态类型（用于 Tag 颜色）
 */
export function getStatusType(status: string): 'success' | 'info' | 'warning' | 'error' | 'default' {
  const typeMap: Record<string, 'success' | 'info' | 'warning' | 'error' | 'default'> = {
    sample_won: 'success',
    negotiating: 'info',
    in_production: 'warning',
    completed: 'success',
    new_round: 'info',
    won_by_others: 'error',
    potential: 'default',
    high_value: 'success',
    no_response: 'warning',
    not_executable: 'error',
    low_priority: 'default'
  }
  return typeMap[status] || 'default'
}

/**
 * 获取订单状态标签
 */
export function getOrderStatusLabel(status: string): string {
  const statusMap: Record<string, string> = {
    pending: '待确认',
    confirmed: '已确认',
    production: '生产中',
    shipped: '已发货',
    completed: '已完成',
    cancelled: '已取消'
  }
  return statusMap[status] || status
}

/**
 * 获取订单状态类型
 */
export function getOrderStatusType(status: string): 'success' | 'info' | 'warning' | 'error' | 'default' {
  const typeMap: Record<string, 'success' | 'info' | 'warning' | 'error' | 'default'> = {
    pending: 'warning',
    confirmed: 'info',
    production: 'warning',
    shipped: 'info',
    completed: 'success',
    cancelled: 'error'
  }
  return typeMap[status] || 'default'
}

/**
 * 获取客户来源标签
 */
export function getSourceLabel(source: string): string {
  const sourceMap: Record<string, string> = {
    website: '网站',
    email: '邮件',
    exhibition: '展会',
    referral: '转介绍',
    cold_call: '电话营销',
    social_media: '社交媒体',
    other: '其他'
  }
  return sourceMap[source] || source
}

/**
 * 获取跟进方式标签
 */
export function getMethodLabel(method: string): string {
  const methodMap: Record<string, string> = {
    email: '邮件',
    phone: '电话',
    whatsapp: 'WhatsApp',
    wechat: '微信',
    meeting: '会议',
    other: '其他'
  }
  return methodMap[method] || method
}

