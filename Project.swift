import ProjectDescription

let project = Project(
    name: "ThePort",
    options: .options(
        defaultKnownRegions: ["en"],
        developmentRegion: "en"
    ),
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "",
            "CODE_SIGN_IDENTITY": "-",
            "CODE_SIGN_STYLE": "Manual"
        ],
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Release")
        ]
    ),
    targets: [
        .target(
            name: "ThePort",
            destinations: .macOS,
            product: .app,
            bundleId: "com.bujosa.theport",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "ThePort",
                "CFBundleName": "ThePort",
                "CFBundleShortVersionString": "0.1.0",
                "CFBundleVersion": "1",
                "LSMinimumSystemVersion": "14.0",
                "NSHumanReadableCopyright": "Copyright © 2024 David Bujosa. All rights reserved.",
                "LSApplicationCategoryType": "public.app-category.developer-tools"
            ]),
            sources: ["ThePort/Sources/**"],
            resources: ["ThePort/Resources/**"],
            entitlements: .file(path: "ThePort.entitlements"),
            dependencies: [
                .external(name: "GRDB")
            ],
            settings: .settings(
                base: [
                    "SWIFT_VERSION": "5.9",
                    "MACOSX_DEPLOYMENT_TARGET": "14.0"
                ]
            )
        )
    ]
)
