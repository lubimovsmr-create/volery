param(
  [Parameter(Mandatory = $true)]
  [string]$Title,
  [string]$Description = "",
  [string]$Lead = "",
  [string]$CardSummary = "",
  [string]$HeroImage = "",
  [string]$HeroAlt = "",
  [string]$MenuTitle = "",
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Escape-Html([string]$s) {
  if ($null -eq $s) { return "" }
  return ($s.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace('"', "&quot;"))
}

function Trim-ForMenu([string]$text, [int]$max = 58) {
  if ([string]::IsNullOrWhiteSpace($text)) { return "" }
  $value = $text.Trim()
  if ($value.Length -le $max) { return $value }
  return $value.Substring(0, $max - 1).TrimEnd() + "…"
}

$root = Split-Path -Parent $PSScriptRoot
$articlesDir = Join-Path $root "articles"
$templatePath = Join-Path $articlesDir "article-template.html"
$articlesIndexPath = Join-Path $articlesDir "index.html"

if (-not (Test-Path $templatePath)) { throw "Не найден шаблон: $templatePath" }
if (-not (Test-Path $articlesIndexPath)) { throw "Не найден список статей: $articlesIndexPath" }

$existingNumbers = @()
Get-ChildItem $articlesDir -File -Filter "article-*.html" | ForEach-Object {
  if ($_.BaseName -match '^article-(\d+)$') { $existingNumbers += [int]$matches[1] }
}
$nextNumber = if ($existingNumbers.Count -gt 0) { ($existingNumbers | Measure-Object -Maximum).Maximum + 1 } else { 1 }

$newFileName = "article-$nextNumber.html"
$newFilePath = Join-Path $articlesDir $newFileName
$articleHrefFromRoot = "articles/$newFileName"
$articleHrefFromArticles = $newFileName
$defaultHeroImage = "../assets/images/articles/article-" + $nextNumber + "-hero.jpg"

if ([string]::IsNullOrWhiteSpace($Description)) {
  $Description = "Практическая статья о выборе и строительстве конструкций для участка: $Title"
}
if ([string]::IsNullOrWhiteSpace($Lead)) {
  $Lead = "Разбираем тему пошагово: на что смотреть в первую очередь, как избежать частых ошибок и какое решение будет оптимальным именно для вашего участка."
}
if ([string]::IsNullOrWhiteSpace($CardSummary)) {
  $CardSummary = "Короткий практический разбор: ключевые критерии, типичные ошибки и рекомендации перед началом работ."
}
if ([string]::IsNullOrWhiteSpace($HeroImage)) { $HeroImage = $defaultHeroImage }
if ([string]::IsNullOrWhiteSpace($HeroAlt)) { $HeroAlt = $Title }
if ([string]::IsNullOrWhiteSpace($MenuTitle)) { $MenuTitle = Trim-ForMenu -text $Title -max 52 }

$templateHtml = Get-Content $templatePath -Raw

$defaultContent = @"
<h2 id="start">Почему это важно</h2>
<p>Правильное решение на старте экономит бюджет и время, а главное - делает будущую конструкцию удобной в ежедневном использовании.</p>

<h2 id="criteria">Ключевые критерии выбора</h2>
<p>Оцените размеры участка, сценарий использования, сезонность, материалы и требования к обслуживанию.</p>
<p>Если заранее определить приоритеты, итоговый проект будет более предсказуемым по срокам и стоимости.</p>

<h2 id="mistakes">Частые ошибки</h2>
<ul>
  <li>Выбор только по внешнему виду без учета эксплуатации</li>
  <li>Недостаточный запас по габаритам и проходам</li>
  <li>Игнорирование ветра, солнца и направления осадков</li>
</ul>

<div class="cta">
  <h2 id="summary">Вывод</h2>
  <p>Оптимальное решение всегда опирается на реальные условия участка и ваш образ жизни. Если нужен быстрый и понятный расчет, мы поможем выбрать лучший вариант под ваши задачи.</p>
  <a class="btn" href="../index.html#contacts">Получить консультацию</a>
</div>
"@

$defaultToc = @"
<ul>
  <li><a href="#start">Почему это важно</a></li>
  <li><a href="#criteria">Ключевые критерии</a></li>
  <li><a href="#mistakes">Частые ошибки</a></li>
  <li><a href="#summary">Вывод</a></li>
</ul>
"@

$replacements = @{
  "{{ARTICLE_TITLE}}" = Escape-Html $Title
  "{{ARTICLE_DESCRIPTION}}" = Escape-Html $Description
  "{{ARTICLE_SLUG_TITLE}}" = Escape-Html (Trim-ForMenu -text $Title -max 42)
  "{{ARTICLE_LEAD}}" = Escape-Html $Lead
  "{{HERO_IMAGE}}" = Escape-Html $HeroImage
  "{{HERO_ALT}}" = Escape-Html $HeroAlt
  "{{ARTICLE_CONTENT_HTML}}" = $defaultContent.Trim()
  "{{TOC_HTML}}" = $defaultToc.Trim()
  "{{RELATED_1_LINK}}" = "article-1.html"
  "{{RELATED_1_IMAGE}}" = "../assets/images/gazebo-01.jpg"
  "{{RELATED_1_ALT}}" = "Беседка или терраса"
  "{{RELATED_1_TITLE}}" = "Беседка или терраса: что лучше выбрать"
  "{{RELATED_2_LINK}}" = "article-2.html"
  "{{RELATED_2_IMAGE}}" = "../assets/images/articles/article-2-hero.jpg"
  "{{RELATED_2_ALT}}" = "Как выбрать хозблок"
  "{{RELATED_2_TITLE}}" = "Как выбрать хозблок для дачи"
  "{{RELATED_3_LINK}}" = "article-3.html"
  "{{RELATED_3_IMAGE}}" = "../assets/images/articles/article-3-hero.jpg"
  "{{RELATED_3_ALT}}" = "Как выбрать навес для машины"
  "{{RELATED_3_TITLE}}" = "Как выбрать навес для машины"
}

$newArticleHtml = $templateHtml
foreach ($key in $replacements.Keys) { $newArticleHtml = $newArticleHtml.Replace($key, $replacements[$key]) }
$newArticleHtml = $newArticleHtml.Replace("../assets/css/articles/article-template.css", "../assets/css/articles/article-1.css")

if ($newArticleHtml -match "\{\{[A-Z0-9_]+\}\}") { throw "Остались незамененные плейсхолдеры" }

$cardHtml = @"
        <article class="article-card">
          <div class="article-thumb"><img src="{0}" alt="{1}" loading="lazy" /></div>
          <div class="article-copy">
            <h2>{2}</h2>
            <p>{3}</p>
            <a class="link" href="{4}">Читать статью</a>
          </div>
        </article>
"@ -f (Escape-Html $HeroImage), (Escape-Html $HeroAlt), (Escape-Html $Title), (Escape-Html $CardSummary), $articleHrefFromArticles

$indexHtml = Get-Content $articlesIndexPath -Raw
$cardHrefMarker = 'class="link" href="' + $articleHrefFromArticles + '"'
if ($indexHtml -notmatch [regex]::Escape($cardHrefMarker)) {
  $indexHtml = [regex]::Replace(
    $indexHtml,
    '(?s)(<section class="articles-grid"[^>]*>)(.*?)(</section>)',
    {
      param($m)
      $existing = $m.Groups[2].Value.TrimEnd()
      return $m.Groups[1].Value + $existing + "`r`n`r`n" + $cardHtml + "`r`n      " + $m.Groups[3].Value
    },
    1
  )
}

function Add-ArticleLinkToMenus([string]$html, [string]$href, [string]$text) {
  $anchor = '<a href="' + $href + '">' + $text + '</a>'
  if ($html.Contains($anchor)) { return $html }

  $desktopPattern = '(?s)(<li class="dropdown desktop-only">\s*<a class="dropdown-toggle" href="[^"]*index\.html">Статьи</a>\s*<div class="dropdown-menu">)(.*?)(</div>\s*</li>)'
  $html = [regex]::Replace($html, $desktopPattern, {
    param($m)
    $inner = $m.Groups[2].Value.TrimEnd()
    return $m.Groups[1].Value + $inner + $anchor + $m.Groups[3].Value
  }, 1)

  $mobilePattern = '(?s)(<li class="mobile-articles">\s*<details>\s*<summary class="nav-link">Статьи</summary>\s*<div class="dropdown-menu"[^>]*>)(.*?)(</div>\s*</details>\s*</li>)'
  $html = [regex]::Replace($html, $mobilePattern, {
    param($m)
    $inner = $m.Groups[2].Value.TrimEnd()
    return $m.Groups[1].Value + $inner + $anchor + $m.Groups[3].Value
  }, 1)

  return $html
}

$allHtmlFiles = Get-ChildItem $root -Recurse -File -Filter "*.html"
$updates = @{}
foreach ($file in $allHtmlFiles) {
  $isInArticles = ($file.DirectoryName -eq $articlesDir)
  $targetHref = if ($isInArticles) { $articleHrefFromArticles } else { $articleHrefFromRoot }
  $raw = Get-Content $file.FullName -Raw
  $updates[$file.FullName] = Add-ArticleLinkToMenus -html $raw -href $targetHref -text (Escape-Html $MenuTitle)
}

# Ensure the newly created article also contains its own menu link
$newArticleHtml = Add-ArticleLinkToMenus -html $newArticleHtml -href $articleHrefFromArticles -text (Escape-Html $MenuTitle)if (-not $DryRun) {
  Set-Content $newFilePath $newArticleHtml -Encoding UTF8
  Set-Content $articlesIndexPath $indexHtml -Encoding UTF8
  foreach ($path in $updates.Keys) { Set-Content $path $updates[$path] -Encoding UTF8 }
}

Write-Output "Создана статья: $newFileName"
Write-Output "Заголовок в меню: $MenuTitle"
Write-Output "Путь: $newFilePath"
if ($DryRun) { Write-Output "DryRun: изменения не записаны." }





