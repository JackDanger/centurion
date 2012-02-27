watch '.*/(.*)\.rb' do
  system "rspec"
end
watch 'src/.*' do
  %x{rake public upload}
end

