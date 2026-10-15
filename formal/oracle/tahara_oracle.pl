:- encoding(utf8).
% =========================================================================
%  Oracle: an independent Prolog model of what exits from the front passage,
%  by its Arabic name (Usul.Tahara), as al-Saʿdī reports the division (F120)
%  and the nuṣūṣ state it (corpus/nusus/foundation.json):
%    al-manī   ṭāhir, ghusl   (ʿĀʾisha's fark; «فإذا فضخت الماء فاغتسل»)
%    al-madhy  najis, wuḍūʾ   («يغسل ذكره ويتوضأ»)
%    al-wadī   najis, wuḍūʾ   (the athar of Ibn ʿAbbās, mawqūf)
%  run_oracle.pl compares it with the rulings the glossary records.
% =========================================================================

:- module(tahara_oracle, [ruling/3]).

% ruling(+TermKey, +Name, -Value)
ruling(K, N, V) :- kharij(K, Najis, Obliges), ( N == najis -> V0 = Najis ; N == obliges -> V0 = Obliges ), V = V0.

kharij(maniyy, false, ghusl).
kharij(madhy,  true,  wudu).
kharij(wady,   true,  wudu).
