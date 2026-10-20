#!/usr/bin/env python3
"""Deterministic self-contained Xcode project generator. No external dependencies."""
from pathlib import Path
import hashlib

ROOT = Path(__file__).parent
SOURCE = ROOT / "orelio"
PBX = ROOT / "orelio.xcodeproj" / "project.pbxproj"

def ident(name):
    return hashlib.sha1(("orelio/" + name).encode()).hexdigest()[:24].upper()

def line(k, values, comment=None):
    return f"\t\t{ident(k)} /* {comment or k.split('/')[-1]} */ = {{ {values} }};"

def ref(name, comment=None):
    return f"{ident(name)} /* {comment or name.split('/')[-1]} */"

source_files = sorted(SOURCE.rglob('*.swift'))
assets = SOURCE / 'Resources' / 'Assets.xcassets'
directories = [SOURCE, *sorted(p for p in SOURCE.rglob('*') if p.is_dir() and p != assets and assets not in p.parents)]

sections = {}
sections['PBXBuildFile'] = []
for path in source_files:
    rel = path.relative_to(SOURCE).as_posix()
    sections['PBXBuildFile'].append(line('build/'+rel,
        f'isa = PBXBuildFile; fileRef = {ref("file/"+rel)};', path.name + ' in Sources'))
sections['PBXBuildFile'].append(line('build/assets', f'isa = PBXBuildFile; fileRef = {ref("file/Resources/Assets.xcassets")};', 'Assets.xcassets in Resources'))

sections['PBXFileReference'] = []
for path in source_files:
    rel=path.relative_to(SOURCE).as_posix()
    sections['PBXFileReference'].append(line('file/'+rel, f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {path.name}; sourceTree = "<group>";'))
sections['PBXFileReference'].append(line('file/Resources/Assets.xcassets', 'isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>";'))
sections['PBXFileReference'].append(line('product', 'isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = orelio.app; sourceTree = BUILT_PRODUCTS_DIR;'))

sections['PBXGroup'] = []
sections['PBXGroup'].append(line('root', 'isa = PBXGroup; children = ( '+ref('sources','orelio')+', '+ref('products','Products')+', ); sourceTree = "<group>";', 'Root'))
sections['PBXGroup'].append(line('products', 'isa = PBXGroup; children = ('+ref('product','orelio.app')+', ); name = Products; sourceTree = "<group>";', 'Products'))
for group in directories:
    rel='.' if group==SOURCE else group.relative_to(SOURCE).as_posix()
    local_files=sorted(p for p in group.iterdir() if p.suffix=='.swift')
    child_dirs=sorted(p for p in group.iterdir() if p.is_dir() and p!=assets and assets not in p.parents)
    children=[ref('group/'+(x.relative_to(SOURCE).as_posix()),x.name) for x in child_dirs]
    children += [ref('file/'+p.relative_to(SOURCE).as_posix(),p.name) for p in local_files]
    if group.name=='Resources': children.append(ref('file/Resources/Assets.xcassets','Assets.xcassets'))
    key='sources' if group==SOURCE else 'group/'+rel
    name='orelio' if group==SOURCE else group.name
    group_path='orelio' if group==SOURCE else group.name
    val='isa = PBXGroup; children = ( '+', '.join(children)+', ); path = '+group_path+'; sourceTree = "<group>";'
    sections['PBXGroup'].append(line(key, val, name))

sections['PBXSourcesBuildPhase']=[line('sourcesBuild', 'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (' + ', '.join(ref('build/'+p.relative_to(SOURCE).as_posix(),p.name+' in Sources') for p in source_files) + ', ); runOnlyForDeploymentPostprocessing = 0;', 'Sources')]
sections['PBXResourcesBuildPhase']=[line('resourceBuild', 'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (' + ref('build/assets','Assets.xcassets in Resources') + ', ); runOnlyForDeploymentPostprocessing = 0;', 'Resources')]
sections['PBXFrameworksBuildPhase']=[line('frameworksBuild', 'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;', 'Frameworks')]
sections['PBXNativeTarget']=[line('target', 'isa = PBXNativeTarget; buildConfigurationList = '+ref('targetConfigs','Build configuration list for PBXNativeTarget "orelio"')+'; buildPhases = ('+ref('sourcesBuild','Sources')+', '+ref('frameworksBuild','Frameworks')+', '+ref('resourceBuild','Resources')+', ); buildRules = (); dependencies = (); name = orelio; productName = orelio; productReference = '+ref('product','orelio.app')+'; productType = "com.apple.product-type.application";', 'orelio')]
sections['PBXProject']=[line('project','isa = PBXProject; attributes = { BuildIndependentTargetsInParallel = 1; LastUpgradeCheck = 1600; TargetAttributes = { '+ident('target')+' = { CreatedOnToolsVersion = 16.0; }; }; }; buildConfigurationList = '+ref('projectConfigs','Build configuration list for PBXProject "orelio"')+'; compatibilityVersion = "Xcode 15.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base, ); mainGroup = '+ref('root','Root')+'; productRefGroup = '+ref('products','Products')+'; projectDirPath = ""; projectRoot = ""; targets = ('+ref('target','orelio')+', );', 'Project object')]

def config(key,name,settings):
    values=' '.join(f'{k} = {v};' for k,v in settings.items())
    return line(key, f'isa = XCBuildConfiguration; buildSettings = {{ {values} }}; name = {name};', name)

common_project={
    'ALWAYS_SEARCH_USER_PATHS':'NO', 'CLANG_ENABLE_MODULES':'YES',
    'CLANG_ENABLE_OBJC_ARC':'YES', 'CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER':'YES',
    'COPY_PHASE_STRIP':'NO', 'IPHONEOS_DEPLOYMENT_TARGET':'17.0',
    'SDKROOT':'iphoneos', 'SWIFT_VERSION':'5.0',
    'SWIFT_OPTIMIZATION_LEVEL':'"-Onone"'
}
project_release=dict(common_project);project_release.update({'COPY_PHASE_STRIP':'YES','SWIFT_OPTIMIZATION_LEVEL':'"-O"','DEBUG_INFORMATION_FORMAT':'"dwarf-with-dsym"'})
common_target={
    'ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME':'AccentColor',
    'ASSETCATALOG_COMPILER_APPICON_NAME':'AppIcon',
    'CODE_SIGN_STYLE':'Automatic', 'CURRENT_PROJECT_VERSION':'1',
    'GENERATE_INFOPLIST_FILE':'YES',
    'INFOPLIST_KEY_CFBundleDisplayName':'orelio',
    'INFOPLIST_KEY_LSSupportsOpeningDocumentsInPlace':'YES',
    'INFOPLIST_KEY_NSPhotoLibraryUsageDescription':'"orelio imports your photos into its local editing library."',
    'INFOPLIST_KEY_UIFileSharingEnabled':'YES',
    'INFOPLIST_KEY_UILaunchScreen_Generation':'YES',
    'MARKETING_VERSION':'0.5.0', 'PRODUCT_BUNDLE_IDENTIFIER':'com.example.orelio',
    'PRODUCT_NAME':'"$(TARGET_NAME)"', 'SUPPORTED_PLATFORMS':'"iphoneos iphonesimulator"',
    'SWIFT_EMIT_LOC_STRINGS':'YES','SWIFT_VERSION':'5.0',
    'TARGETED_DEVICE_FAMILY':'"1,2"'
}
sections['XCBuildConfiguration']=[config('projectDebug','Debug',common_project),config('projectRelease','Release',project_release),config('targetDebug','Debug',common_target),config('targetRelease','Release',common_target)]
sections['XCConfigurationList']=[
 line('projectConfigs','isa = XCConfigurationList; buildConfigurations = ('+ref('projectDebug','Debug')+', '+ref('projectRelease','Release')+', ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;', 'Build configuration list for PBXProject "orelio"'),
 line('targetConfigs','isa = XCConfigurationList; buildConfigurations = ('+ref('targetDebug','Debug')+', '+ref('targetRelease','Release')+', ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;', 'Build configuration list for PBXNativeTarget "orelio"'),
]
order=['PBXBuildFile','PBXFileReference','PBXFrameworksBuildPhase','PBXGroup','PBXNativeTarget','PBXProject','PBXResourcesBuildPhase','PBXSourcesBuildPhase','XCBuildConfiguration','XCConfigurationList']
parts=['// !$*UTF8*$!', '{', '\tarchiveVersion = 1;', '\tclasses = {};','\tobjectVersion = 60;', '\tobjects = {']
for name in order:
    parts.append(f'\n/* Begin {name} section */')
    parts.extend(sections[name])
    parts.append(f'/* End {name} section */\n')
parts.extend(['\t};','\trootObject = '+ref('project','Project object')+';','}'])
PBX.write_text('\n'.join(parts)+'\n')
print('Created',PBX,'Swift sources:',len(source_files))
