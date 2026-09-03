from pathlib import Path

path = Path('apps/mobile-flutter/lib/features/home/presentation/screens/home_tab.dart')
text = path.read_text(encoding='utf-8')

old = '''    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: _LanguageChannelCard(
            language: language,
            languageName: languageName,
            onChangeLanguage: onChangeLanguage,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: _InterestOverviewCard(
            interestedCount: interestedCount,
            totalCount: totalCount,
            interestsLoaded: interestsLoaded,
          ),
        ),
      ],
    );'''

new = '''    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: _LanguageChannelCard(
              language: language,
              languageName: languageName,
              onChangeLanguage: onChangeLanguage,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: _InterestOverviewCard(
              interestedCount: interestedCount,
              totalCount: totalCount,
              interestsLoaded: interestsLoaded,
            ),
          ),
        ],
      ),
    );'''

if old not in text:
    raise SystemExit('Category overview row did not match current main')

path.write_text(text.replace(old, new, 1), encoding='utf-8')
