function out = urlencoder(query_string)
sym = {'"','{',':',',',';','}','/','[',']','$','+','\';
    '"%"22','"%"7B','"%"3A','"%"2C','"%"3B','"%"7D','"%"2F','"%"5B','"%"5D','"%"24','"%"2B','"%"2F'};
[~,n] = size(sym);
out =query_string;
for i=1:n
    out = strrep(out,sym{1,i},sym{2,i});
end
end