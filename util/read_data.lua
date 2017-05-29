--[[

  Functions for loading data from disk.

--]]

function similarityMeasure.read_embedding(vocab_path, emb_path)
  local vocab = similarityMeasure.Vocab(vocab_path)
  local embedding = torch.load(emb_path)
  return vocab, embedding
end

function similarityMeasure.read_sentences(path, vocab)
  local sentences = {}
  local file = io.open(path, 'r')
  local line
  
  local fixed = true
  local aa = 0
  while true do
    line = file:read()
    if line == nil then break end
    aa = aa + 1
    local tokens = stringx.split(line)
    local len = #tokens
    local padLen = len
    if fixed and len < 3 then
      padLen = 3
    end
    local sent = torch.IntTensor(padLen)
    for i = 1, len do
      local token = tokens[i]
      sent[i] = vocab:index(token)
    end
    if fixed and len < 3 then
      for i = len+1, padLen do
        --print(sent)
        print(aa)
        sent[i] = vocab:index("unk") -- sent[len]
      end
    end
    sentences[#sentences + 1] = sent
  end
  
  file:close()
  return sentences
end

function similarityMeasure.read_relatedness_dataset(dir, vocab, task)
  local dataset = {}
  dataset.vocab = vocab
  dataset.lsents = similarityMeasure.read_sentences(dir .. 'a.toks', vocab)
  dataset.rsents = similarityMeasure.read_sentences(dir .. 'b.toks', vocab)
  dataset.size = #dataset.lsents
  local id_file = torch.DiskFile(dir .. 'id.txt')
  local sim_file = torch.DiskFile(dir .. 'sim.txt')
  dataset.ids = torch.IntTensor(dataset.size)
  dataset.labels = torch.Tensor(dataset.size)
  for i = 1, dataset.size do
    dataset.ids[i] = id_file:readInt()
    if task == 'sic' then
    	dataset.labels[i] = 0.25 * (sim_file:readDouble() - 1) -- sic data
    elseif task == 'vid' then
	    dataset.labels[i] = 0.2 * (sim_file:readDouble()) -- vid data
    elseif task == 'vid2' then
	    dataset.labels[i] = 0.2 * (sim_file:readDouble()) -- vid2 data
    elseif task == 'msp' then
        --print(dir)
	    dataset.labels[i] =  (sim_file:readDouble()) -- msp data
    elseif task == 'quo' then
	    dataset.labels[i] = (sim_file:readDouble()) -- quora data
    else
    	dataset.labels[i] = (sim_file:readDouble()) -- twi and msp
    end
  end
  id_file:close()
  sim_file:close()
  return dataset
end

