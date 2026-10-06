# Sinhala frequency model attribution

`SinhalaFrequencyModel.tsv` is a compact, frequency-sorted derivative of the
University of Moratuwa National Languages Processing Centre's **A Word
Frequency List for Sinhala**. It retains the first 40,000 highest-frequency
entries from `word_frequency_list_2M.si`, filters malformed or overlong
tokens and a small exact-match blocked-token list
(`Scripts/SinhalaBlockedWords.txt`), then sorts them by word for compact
on-device prefix lookup.

Source: https://github.com/nlpcuom/Word-Frequency-List-for-Sinhala

Citation:

> Aloka Fernando and Gihan Dias. 2021. Building a Linguistic Resource: A Word
> Frequency List for Sinhala. Proceedings of the 18th International Conference
> on Natural Language Processing (ICON), pages 606–610.

The source author confirmed open-source use for this project. Keep this
attribution with any redistribution or regenerated model artifact.
