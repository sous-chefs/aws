describe 'SSM Parameter Store' do
  subject(:params) { json('/tmp/ssm_parameters.json') }

  describe.one do
    context 'when getting parameter values' do
      it 'returns the clear text value' do
        expect(params.clear_value).to eq('Clear Text Test Kitchen')
      end

      it 'returns the decrypted value' do
        expect(params.decrypted_value).to eq('Encrypted Test Kitchen Default')
      end

      it 'returns the value of a parameter at a specific path' do
        expect(params.parameter_values['/testkitchen']).to eq('testkitchen')
        expect(params.parameter_values['/testkitchen/ClearTextString']).to eq('Clear Text Test Kitchen')
      end
    end

    context 'when getting parameter values by path' do
      it 'returns a hash of values at a specific path' do
        expect(params.path_values['path1']).to eq('path1_value')
        expect(params.path_values['path2']).to eq('path2_value')
      end
    end
  end

  it 'returns the value of a specific parameter' do
    expect(params.parm1_value).to eq('Clear Text Test Kitchen')
    expect(params.parm2_value).to eq('testkitchen')
  end
end
